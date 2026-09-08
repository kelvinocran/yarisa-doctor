import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

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

  Future<void> _save(BuildContext context, String key, bool value) async {
    try {
      await _updatePreference(key, value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save preference')),
      );
    }
  }

  Future<void> _enableAll(BuildContext context, String doctorId) async {
    try {
      final payload = <String, dynamic>{
        for (final e in _defaults.entries)
          'notificationPreferences.${e.key}': e.value,
        'notificationPreferences.updatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .set(payload, SetOptions(merge: true));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notification preferences enabled')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update preferences')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    return DoctorScaffold(
      title: 'Notification preferences',
      subtitle: 'Choose what alerts you receive',
      showBack: Navigator.of(context).canPop(),
      actions: doctorId == null
          ? null
          : [
              TextButton(
                onPressed: () => _enableAll(context, doctorId),
                child: const Text('Enable all'),
              ),
            ],
      body: doctorId == null
          ? const DoctorEmptyState(
              icon: EneftyIcons.notification_outline,
              title: 'Sign in required',
              message: 'Sign in again to manage notifications.',
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .doc(doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  );
                }
                if (snapshot.hasError) {
                  return DoctorEmptyState(
                    icon: EneftyIcons.warning_2_outline,
                    title: 'Could not load preferences',
                    message: snapshot.error.toString(),
                  );
                }

                final preferences = _parsePreferences(snapshot.data?.data());
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    DoctorCard(
                      child: Text(
                        'Control which Yarisa updates should alert you. Critical account and safety notices may still be delivered.',
                        style: TextStyle(
                          color: DoctorUi.muted,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DoctorCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final entry in [
                            (
                              'appointments',
                              EneftyIcons.calendar_2_outline,
                              'Appointments',
                              'Bookings, cancellations, reschedules',
                            ),
                            (
                              'messages',
                              EneftyIcons.message_2_outline,
                              'Messages',
                              'Patient conversations',
                            ),
                            (
                              'secondOpinions',
                              EneftyIcons.health_outline,
                              'Second opinions',
                              'New requests and responses',
                            ),
                            (
                              'prescriptions',
                              EneftyIcons.document_text_outline,
                              'Prescriptions',
                              'Rx activity and follow-ups',
                            ),
                            (
                              'labRequests',
                              EneftyIcons.bucket_outline,
                              'Lab requests',
                              'Orders and result updates',
                            ),
                            (
                              'patientUpdates',
                              EneftyIcons.profile_2user_outline,
                              'Patient updates',
                              'New patients and profile changes',
                            ),
                            (
                              'platformAlerts',
                              EneftyIcons.notification_outline,
                              'Platform alerts',
                              'Product news and maintenance',
                            ),
                          ]) ...[
                            _PreferenceSwitch(
                              icon: entry.$2,
                              title: entry.$3,
                              subtitle: entry.$4,
                              value: preferences[entry.$1]!,
                              onChanged: (v) =>
                                  _save(context, entry.$1, v),
                            ),
                            if (entry.$1 != 'platformAlerts') _div(),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _div() => Divider(height: 1, color: DoctorUi.border);

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase().trim();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  Map<String, bool> _parsePreferences(Map<String, dynamic>? data) {
    final map = <String, bool>{..._defaults};
    final raw = data?['notificationPreferences'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final parsed = _asBool(entry.value);
        if (parsed != null) {
          map[entry.key.toString()] = parsed;
        }
      }
    }
    return map;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DoctorUi.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DoctorUi.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: DoctorUi.primary.withValues(alpha: .45),
            activeThumbColor: DoctorUi.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
