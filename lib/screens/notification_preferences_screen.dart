import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/yarisa_enums.dart';
import '../constants/yarisa_widgets.dart';

class DoctorNotificationPreferencesScreen extends StatelessWidget {
  const DoctorNotificationPreferencesScreen({super.key});

  static const _defaults = <String, bool>{
    'appointments': true,
    'messages': true,
    'secondOpinions': true,
    'prescriptions': true,
    'labRequests': true,
    'patientUpdates': true,
    'platformAlerts': true,
  };

  Future<void> _updatePreference(String key, bool value) async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return;

    await FirebaseFirestore.instance.collection('Doctors').doc(doctorId).set({
      'notificationPreferences.$key': value,
      'notificationPreferences.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: yarisaAppBar(context, title: 'Notifications'),
      body: doctorId == null
          ? const Center(child: Text('Sign in again to manage notifications.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .doc(doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                final preferences = _parsePreferences(snapshot.data?.data());
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const YarisaText(
                        text:
                            'Control which Yarisa updates should alert you while keeping account and safety notices available.',
                        type: TextType.bodySmall,
                        lines: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PreferenceSwitch(
                      icon: EneftyIcons.calendar_2_outline,
                      title: 'Appointments',
                      subtitle: 'Bookings, cancellations, and reschedules',
                      value: preferences['appointments'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'appointments', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.message_2_outline,
                      title: 'Messages',
                      subtitle: 'Patient and support conversations',
                      value: preferences['messages'] ?? true,
                      onChanged: (value) => _save(context, 'messages', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.health_outline,
                      title: 'Second opinions',
                      subtitle: 'New requests, responses, and calls',
                      value: preferences['secondOpinions'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'secondOpinions', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.document_text_outline,
                      title: 'Prescriptions',
                      subtitle: 'Prescription activity and follow-ups',
                      value: preferences['prescriptions'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'prescriptions', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.bucket_outline,
                      title: 'Lab requests',
                      subtitle: 'Lab order and result activity',
                      value: preferences['labRequests'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'labRequests', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.profile_2user_outline,
                      title: 'Patient updates',
                      subtitle: 'New personal doctors and profile changes',
                      value: preferences['patientUpdates'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'patientUpdates', value),
                    ),
                    _PreferenceSwitch(
                      icon: EneftyIcons.notification_outline,
                      title: 'Platform alerts',
                      subtitle: 'Yarisa operational updates',
                      value: preferences['platformAlerts'] ?? true,
                      onChanged: (value) =>
                          _save(context, 'platformAlerts', value),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _save(BuildContext context, String key, bool value) async {
    try {
      await _updatePreference(key, value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update preference.')),
        );
      }
    }
  }

  Map<String, bool> _parsePreferences(Map<String, dynamic>? data) {
    final raw = data?['notificationPreferences'];
    if (raw is! Map) return _defaults;
    return {
      ..._defaults,
      for (final entry in raw.entries)
        if (entry.value is bool) entry.key.toString(): entry.value as bool,
    };
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
