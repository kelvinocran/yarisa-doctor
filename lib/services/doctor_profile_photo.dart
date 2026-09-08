import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Pick + upload doctor avatar with clear progress and error feedback.
class DoctorProfilePhoto {
  DoctorProfilePhoto._();

  static Future<ImageSource?> chooseSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: DoctorUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: DoctorUi.border,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const Text(
                  'Update profile photo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns the download URL on success, or null if cancelled.
  static Future<String?> pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    ImageSource? source,
  }) async {
    final pickedSource = source ?? await chooseSource(context);
    if (pickedSource == null) return null;

    final file = await ImagePicker().pickImage(
      source: pickedSource,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return null;
    if (!context.mounted) return null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast(context, 'Sign in again to update your photo.');
      return null;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.4),
                SizedBox(height: 14),
                Text('Uploading photo…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');
      await storageRef.putFile(
        File(file.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();

      await ref.read(apimethods).updateDoctorProfile({
        'pic': url,
        'photo': url,
      });

      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      } catch (e) {
        if (kDebugMode) debugPrint('updatePhotoURL failed: $e');
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _toast(context, 'Profile photo updated');
      }
      return url;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _toast(context, 'Failed to update photo: $e');
      }
      return null;
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
