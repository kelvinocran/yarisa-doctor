import 'dart:io';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/models/user_model.dart';
import 'package:yarisa_doctor/services/doctor_profile_photo.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Full-screen redesigned doctor profile editor.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.initialUser});

  final UserModel? initialUser;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late final TextEditingController _clinic;
  late final TextEditingController _speciality;
  late final TextEditingController _location;
  late final TextEditingController _experience;

  bool _saving = false;
  bool _uploadingPic = false;
  String? _localPicPath;
  String? _remotePic;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser ?? ref.read(apimethods).userAccount;
    _name = TextEditingController(text: user?.fullname ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    _clinic = TextEditingController(text: user?.clinic ?? '');
    _speciality = TextEditingController(text: user?.speciality ?? '');
    _location = TextEditingController(text: user?.location ?? '');
    _experience = TextEditingController(
      text: user?.experience == null ? '' : '${user!.experience}',
    );
    _remotePic = user?.pic;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _clinic.dispose();
    _speciality.dispose();
    _location.dispose();
    _experience.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: DoctorUi.fieldBg,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 18, color: DoctorUi.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPic) return;
    setState(() => _uploadingPic = true);
    try {
      final url = await DoctorProfilePhoto.pickAndUpload(context, ref);
      if (url == null || !mounted) return;
      setState(() {
        _remotePic = url;
        _localPicPath = null;
      });
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  Future<String?> _uploadPicIfNeeded() async {
    // Photos upload immediately on pick; keep remote URL for form save.
    return _remotePic;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'No signed-in doctor found.',
        );
      }

      final name = _name.text.trim();
      final picUrl = await _uploadPicIfNeeded();
      await currentUser.updateDisplayName(name);

      final expText = _experience.text.trim();
      final exp = expText.isEmpty ? null : int.tryParse(expText);

      final payload = <String, dynamic>{
        'fullname': name,
        'phone': _phone.text.trim(),
        'bio': _bio.text.trim(),
        'clinic': _clinic.text.trim(),
        'speciality': _speciality.text.trim(),
        'location': _location.text.trim(),
        if (exp != null) 'experience': exp,
        if (picUrl != null && picUrl.isNotEmpty) 'pic': picUrl,
      };

      await ref.read(apimethods).updateDoctorProfile(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ??
        widget.initialUser?.email ??
        '';

    return DoctorScaffold(
      title: 'Edit profile',
      subtitle: 'How patients see you',
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DoctorCard(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DoctorUi.primary.withValues(alpha: .25),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _localPicPath != null
                                    ? Image.file(
                                        File(_localPicPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_remotePic != null &&
                                            _remotePic!.isNotEmpty)
                                        ? Image.network(
                                            _remotePic!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _avatarFallback(),
                                          )
                                        : _avatarFallback(),
                              ),
                            ),
                            Material(
                              color: DoctorUi.primary,
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: _uploadingPic ? null : _pickPhoto,
                                icon: _uploadingPic
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          email.isEmpty ? 'Your public profile' : email,
                          style: TextStyle(
                            color: DoctorUi.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _uploadingPic ? null : _pickPhoto,
                          icon: const Icon(Icons.photo_outlined, size: 18),
                          label: Text(
                            _localPicPath != null
                                ? 'Change photo'
                                : 'Update photo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const DoctorSectionHeader(title: 'Basic info'),
                  DoctorCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dec(
                            'Full name',
                            icon: EneftyIcons.user_outline,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _speciality,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dec(
                            'Speciality',
                            hint: 'e.g. Cardiology',
                            icon: EneftyIcons.hospital_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _dec(
                            'Phone',
                            icon: EneftyIcons.call_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _experience,
                          keyboardType: TextInputType.number,
                          decoration: _dec(
                            'Years of experience',
                            icon: EneftyIcons.medal_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const DoctorSectionHeader(title: 'Practice'),
                  DoctorCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _clinic,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dec(
                            'Clinic / hospital',
                            icon: EneftyIcons.building_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _location,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dec(
                            'Location',
                            hint: 'City or area',
                            icon: EneftyIcons.location_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bio,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            'Bio',
                            hint: 'A short intro for patients',
                            icon: EneftyIcons.document_text_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: DoctorUi.surface,
              border: Border(top: BorderSide(color: DoctorUi.border)),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _saving || _uploadingPic ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorUi.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save profile',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return ColoredBox(
      color: DoctorUi.fieldBg,
      child: Center(
        child: Icon(
          EneftyIcons.user_outline,
          size: 40,
          color: DoctorUi.primary.withValues(alpha: .5),
        ),
      ),
    );
  }
}

