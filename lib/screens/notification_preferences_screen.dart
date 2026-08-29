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

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    return DoctorScaffold(
      title: 'Notification preferences',
      subtitle: 'Choose what alerts you receive',
      showBack: Navigator.of(context).canPop(),
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
                          _PreferenceSwitch(
                            icon: EneftyIcons.calendar_2_outline,
                            title: 'Appointments',
                            subtitle: 'Bookings, cancellations, reschedules',
                            value: preferences['appointments'] ?? true,
                            onChanged: (v) => _save(context, 'appointments', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.message_2_outline,
                            title: 'Messages',
                            subtitle: 'Patient conversations',
                            value: preferences['messages'] ?? true,
                            onChanged: (v) => _save(context, 'messages', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.health_outline,
                            title: 'Second opinions',
                            subtitle: 'New requests and responses',
                            value: preferences['secondOpinions'] ?? true,
                            onChanged: (v) =>
                                _save(context, 'secondOpinions', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.document_text_outline,
                            title: 'Prescriptions',
                            subtitle: 'Rx activity and follow-ups',
                            value: preferences['prescriptions'] ?? true,
                            onChanged: (v) =>
                                _save(context, 'prescriptions', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.bucket_outline,
                            title: 'Lab requests',
                            subtitle: 'Orders and result updates',
                            value: preferences['labRequests'] ?? true,
                            onChanged: (v) => _save(context, 'labRequests', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.profile_2user_outline,
                            title: 'Patient updates',
                            subtitle: 'New patients and profile changes',
                            value: preferences['patientUpdates'] ?? true,
                            onChanged: (v) =>
                                _save(context, 'patientUpdates', v),
                          ),
                          _div(),
                          _PreferenceSwitch(
                            icon: EneftyIcons.notification_outline,
                            title: 'Platform alerts',
                            subtitle: 'Product news and maintenance',
                            value: preferences['platformAlerts'] ?? true,
                            onChanged: (v) =>
                                _save(context, 'platformAlerts', v),
                          ),
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

  Map<String, bool> _parsePreferences(Map<String, dynamic>? data) {
    final raw = data?['notificationPreferences'];
    final map = <String, bool>{..._defaults};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is bool) {
          map[entry.key.toString()] = entry.value as bool;
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
