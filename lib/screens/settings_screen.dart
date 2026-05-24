import 'dart:io';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:images_picker/images_picker.dart';

import '../api/api_methods.dart';
import '../constants/yarisa_enums.dart';
import '../constants/yarisa_strings.dart';
import '../constants/yarisa_widgets.dart';
import '../models/user_model.dart';
import 'notification_preferences_screen.dart';
import 'authentication/welcome_screen.dart';
import '../widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uploadingPic = false;

  Future<void> _updateProfilePic() async {
    try {
      final res = await ImagesPicker.pick(
        count: 1,
        pickType: PickType.image,
        cropOpt: CropOption(cropType: CropType.circle),
      );
      if (res == null || res.isEmpty) return;

      setState(() => _uploadingPic = true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');
      await storageRef.putFile(File(res.first.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await ref.read(apimethods).updateDoctorProfile({'pic': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  Future<void> _showEditProfileSheet(UserModel user) async {
    final nameCtrl = TextEditingController(text: user.fullname ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final bioCtrl = TextEditingController(text: user.bio ?? '');
    final clinicCtrl = TextEditingController(text: user.clinic ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveProfile() async {
              if (formKey.currentState?.validate() != true) return;
              setSheetState(() => saving = true);
              var shouldCloseSheet = false;

              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  throw FirebaseAuthException(
                    code: 'not-authenticated',
                    message: 'No signed-in doctor found.',
                  );
                }

                final updatedName = nameCtrl.text.trim();
                await currentUser.updateDisplayName(updatedName);
                await ref.read(apimethods).updateDoctorProfile({
                  'fullname': updatedName,
                  'phone': phoneCtrl.text.trim(),
                  'bio': bioCtrl.text.trim(),
                  'clinic': clinicCtrl.text.trim(),
                });

                shouldCloseSheet = true;
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e')),
                  );
                }
              } finally {
                if (!shouldCloseSheet && sheetContext.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: clinicCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Clinic / Hospital',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : saveProfile,
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } finally {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      bioCtrl.dispose();
      clinicCtrl.dispose();
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to manage your Yarisa account.',
      confirmLabel: 'Sign Out',
      icon: EneftyIcons.logout_outline,
      isDestructive: true,
    );
    if (!confirmed) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(apimethods).userAccount;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const YarisaText(
          text: AppStrings.settings,
          type: TextType.appbar,
          size: 18,
        ),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: .2)),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            safeCachedNetworkImageProvider(user?.pic),
                        child: safeCachedNetworkImageProvider(user?.pic) == null
                            ? const Icon(EneftyIcons.user_outline, size: 32)
                            : null,
                      ),
                      if (_uploadingPic)
                        const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullname ?? 'Doctor',
                          style: theme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (user?.speciality != null)
                          Text(
                            user!.speciality!,
                            style:
                                theme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        Text(
                          user?.email ??
                              FirebaseAuth.instance.currentUser?.email ??
                              '',
                          style: theme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ACCOUNT',
              style: theme.bodySmall?.copyWith(
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              onTap: _updateProfilePic,
              leading: const Icon(EneftyIcons.image_outline),
              trailing: _uploadingPic
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              title: const Text('Update Profile Picture'),
            ),
            ListTile(
              onTap: () {
                if (user != null) _showEditProfileSheet(user);
              },
              leading: const Icon(EneftyIcons.edit_2_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Edit Profile'),
              subtitle: const Text('Name, phone, bio, clinic'),
            ),
            ListTile(
              onTap: _sendPasswordReset,
              leading: const Icon(EneftyIcons.lock_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Change Password'),
              subtitle: const Text('A reset link will be emailed to you'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorNotificationPreferencesScreen(),
                  ),
                );
              },
              leading: const Icon(EneftyIcons.notification_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Notification Preferences'),
              subtitle: const Text('Appointments, messages, second opinions'),
            ),
            const SizedBox(height: 24),
            Text(
              'APP',
              style: theme.bodySmall?.copyWith(
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(EneftyIcons.info_circle_outline),
              title: Text('App Version'),
              subtitle: Text('1.0.1 (build 2)'),
            ),
            const SizedBox(height: 40),
            ListTile(
              tileColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onTap: _signOut,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
              ),
              leading: const Icon(
                EneftyIcons.logout_outline,
                color: Colors.white,
              ),
              title: Text(
                'Sign Out',
                style: theme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Log out of your Yarisa Healthcare account.',
                style: theme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
