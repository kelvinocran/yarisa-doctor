import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class PatientListTileCard extends StatelessWidget {
  const PatientListTileCard({
    super.key,
    required this.patient,
    required this.onTap,
    this.subtitle,
  });

  final PersonalPatientsModel patient;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final status = (patient.status ?? 'active').trim();
    final statusColor = status.toLowerCase() == 'active'
        ? Colors.green
        : DoctorUi.muted;

    return DoctorCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleImage(size: 48, image: patient.patientImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientName?.trim().isNotEmpty == true
                      ? patient.patientName!
                      : 'Patient',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle ??
                      (status.isEmpty ? 'Patient' : status.capitalizeStatus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DoctorUi.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              status.isEmpty ? 'Active' : status.capitalizeStatus,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: DoctorUi.muted),
        ],
      ),
    );
  }
}

class PatientHeroHeader extends StatelessWidget {
  const PatientHeroHeader({
    super.key,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  final String name;
  final String email;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      child: Column(
        children: [
          CircleImage(size: 88, image: imageUrl),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(color: DoctorUi.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class PatientActionGrid extends StatelessWidget {
  const PatientActionGrid({super.key, required this.actions});

  final List<PatientActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final a = actions[i];
        return DoctorCard(
          onTap: a.onTap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, color: a.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  a.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PatientActionItem {
  const PatientActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class PatientMetricGrid extends StatelessWidget {
  const PatientMetricGrid({super.key, required this.metrics});

  final List<PatientMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final m = metrics[i];
        return DoctorCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                m.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: m.value == 'Not set' ? DoctorUi.muted : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                m.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DoctorUi.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PatientMetric {
  const PatientMetric({required this.label, required this.value});
  final String label;
  final String value;
}

extension on String {
  String get capitalizeStatus {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Shared empty state copy for patient lists.
class PatientsEmptyState extends StatelessWidget {
  const PatientsEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DoctorEmptyState(
      icon: EneftyIcons.profile_2user_outline,
      title: title,
      message: message,
    );
  }
}
