import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/api/firestore_schema.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/screens/main/base.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class DoctorVerificationPendingScreen extends StatefulWidget {
  const DoctorVerificationPendingScreen({
    super.key,
    this.initialProfileData,
  });

  final Map<String, dynamic>? initialProfileData;

  @override
  State<DoctorVerificationPendingScreen> createState() =>
      _DoctorVerificationPendingScreenState();
}

class _DoctorVerificationPendingScreenState
    extends State<DoctorVerificationPendingScreen> {
  bool _routingToBase = false;
  bool _refreshing = false;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshStatus(String doctorId) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final snapshot = await FirestoreSchema.doctorDoc(doctorId).get();
      final data = snapshot.data();
      if (data?['isVerified'] == true) {
        _routeToBase();
        return;
      }
      if (!mounted) return;
      showDoctorAuthSnack(
        context,
        'Your verification is still pending.',
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _routeToBase() {
    if (_routingToBase || !mounted) return;
    _routingToBase = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BaseScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      });
      return Scaffold(
        backgroundColor: DoctorUi.scaffoldBg,
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreSchema.doctorDoc(doctor.uid).snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? widget.initialProfileData;
        if (profileData?['isVerified'] == true) {
          _routeToBase();
          return Scaffold(
            backgroundColor: DoctorUi.scaffoldBg,
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final verificationStatus =
            profileData?['verificationStatus']?.toString().trim().toLowerCase();
        final status = verificationStatus == null || verificationStatus.isEmpty
            ? 'pending'
            : verificationStatus;
        final statusTone = _statusTone(status);

        return DoctorAuthScaffold(
          showBack: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Account review',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: DoctorUi.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signOut,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: DoctorUi.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DoctorAuthHeader(
                title: _statusTitle(status),
                subtitle: _statusMessage(status),
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusTone.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: statusTone.withValues(alpha: .3)),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: statusTone,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _ReviewSummary(profileData: profileData ?? const {}),
              const SizedBox(height: 16),
              _ReviewSteps(status: status, color: statusTone),
              const SizedBox(height: 28),
              DoctorAuthPrimaryButton(
                label: 'Refresh status',
                loading: _refreshing,
                icon: Icons.refresh_rounded,
                onPressed: () => _refreshStatus(doctor.uid),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.profileData});

  final Map<String, dynamic> profileData;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _SummaryRow('Name', _stringValue(profileData['fullname'])),
      _SummaryRow('Specialty', _stringValue(profileData['speciality'])),
      _SummaryRow('Clinic', _stringValue(profileData['clinic'])),
      _SummaryRow('License code', _stringValue(profileData['licenseCode'])),
    ].where((row) => row.value.isNotEmpty).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return DoctorAuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submitted profile',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSteps extends StatelessWidget {
  const _ReviewSteps({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected' || status == 'declined';

    return DoctorAuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review progress',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _StepTile(label: 'Profile submitted', active: true, color: color),
          _StepTile(
            label: rejected ? 'Update requested' : 'License review',
            active: true,
            color: color,
          ),
          _StepTile(
            label: 'Approval to accept bookings',
            active: false,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.label,
    required this.active,
    required this.color,
  });

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: active ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(
              active ? Icons.check_rounded : Icons.more_horiz_rounded,
              color: active ? Colors.white : color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;
}

String _stringValue(dynamic value) => value?.toString().trim() ?? '';

String _statusTitle(String status) {
  switch (status) {
    case 'rejected':
    case 'declined':
      return 'Verification needs attention';
    case 'approved':
    case 'verified':
      return 'Verification approved';
    case 'under_review':
    case 'in_review':
      return 'Verification in review';
    default:
      return 'Verification pending';
  }
}

String _statusMessage(String status) {
  switch (status) {
    case 'rejected':
    case 'declined':
      return 'Your profile needs another look before patients can book appointments with you. Contact support or update the requested details.';
    case 'under_review':
    case 'in_review':
      return 'The Yarisa team is reviewing your professional details and license before your availability can go live.';
    default:
      return 'Your profile has been submitted. The Yarisa team will approve your account before patients can book with you.';
  }
}

Color _statusTone(String status) {
  switch (status) {
    case 'rejected':
    case 'declined':
      return Colors.red.shade600;
    case 'under_review':
    case 'in_review':
      return Colors.orange.shade700;
    default:
      return DoctorUi.primary;
  }
}
