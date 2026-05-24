import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/api/firestore_schema.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/screens/main/base.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your verification is still pending.')),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreSchema.doctorDoc(doctor.uid).snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? widget.initialProfileData;
        if (profileData?['isVerified'] == true) {
          _routeToBase();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final verificationStatus =
            profileData?['verificationStatus']?.toString().trim().toLowerCase();
        final status = verificationStatus == null || verificationStatus.isEmpty
            ? 'pending'
            : verificationStatus;
        final statusTone = _statusTone(status);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Account review'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusHeader(status: status, color: statusTone),
                  24.hgap,
                  _ReviewSummary(profileData: profileData ?? const {}),
                  20.hgap,
                  _ReviewSteps(status: status, color: statusTone),
                  28.hgap,
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _refreshing
                              ? null
                              : () => _refreshStatus(doctor.uid),
                          icon: _refreshing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh status'),
                        ),
                      ),
                    ],
                  ),
                  8.hgap,
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.verified_user_outlined, color: color, size: 32),
        ),
        18.hgap,
        YarisaText(
          text: _statusTitle(status),
          type: TextType.heading,
          weight: FontWeight.w700,
          spacing: 0,
          height: 1.1,
          size: YarisaDimens.headlineMedium + 2,
        ),
        10.hgap,
        Text(
          _statusMessage(status),
          style: context.bodyMedium?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
            height: 1.45,
          ),
        ),
      ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YarisaText(
            text: 'Submitted profile',
            type: TextType.bodyBig,
            weight: FontWeight.w700,
          ),
          14.hgap,
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        row.label,
                        style: context.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: context.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YarisaText(
            text: 'Review progress',
            type: TextType.bodyBig,
            weight: FontWeight.w700,
          ),
          14.hgap,
          _StepTile(
            label: 'Profile submitted',
            active: true,
            color: color,
          ),
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
          12.wgap,
          Expanded(
            child: Text(
              label,
              style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

String _stringValue(dynamic value) {
  return value?.toString().trim() ?? '';
}

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
      return 'Your profile needs another look before patients can book appointments with you. Contact Yarisa support or update the requested details.';
    case 'under_review':
    case 'in_review':
      return 'The Yarisa team is reviewing your professional details and license before your availability can go live.';
    default:
      return 'Your profile has been submitted. The Yarisa team will approve your account before patients can book appointments with you.';
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
      return Colors.purple.shade700;
  }
}
