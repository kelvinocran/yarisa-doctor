import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/services/chat_unread_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// In-app activity feed for the doctor (bottom-nav Alerts tab).
/// Prefers `Notifications` docs, and merges recent bookings / new patients
/// so the list is useful even before push history is dense.
class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _markRead(String id, {String? peerId}) async {
    // Also clear matching chat-thread unread so nav badges stay in sync.
    await ChatUnreadService.markThreadReadFromNotification(
      peerId: peerId,
      notificationId: id,
    );
  }

  Future<void> _markAllRead(String doctorId) async {
    try {
      // Single-field query only (avoids composite index on recipientId + read).
      final snap = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('recipientId', isEqualTo: doctorId)
          .get();
      final unread = snap.docs.where((d) => d.data()['read'] != true).toList();
      if (unread.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nothing to mark as read')),
          );
        }
        return;
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread) {
        batch.set(
          doc.reference,
          {'read': true, 'readAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read')),
      );
    }
  }

  void _openItem(_FeedItem item) {
    if (item.notificationId != null) {
      _markRead(item.notificationId!, peerId: item.patientId);
    } else if ((item.patientId ?? '').isNotEmpty &&
        (item.kind == _FeedKind.message || item.kind == _FeedKind.call)) {
      ChatUnreadService.markThreadRead(item.patientId!);
    }
    final nav = Navigator.of(context);
    switch (item.kind) {
      case _FeedKind.call:
      case _FeedKind.message:
        if ((item.patientId ?? '').isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => DoctorMessageThreadScreen(
                patientId: item.patientId!,
                patientName: item.patientName ?? 'Patient',
                patientImage: item.imageUrl ?? '',
              ),
            ),
          );
        } else {
          nav.push(
            MaterialPageRoute(builder: (_) => const DoctorChatInboxScreen()),
          );
        }
        break;
      case _FeedKind.appointment:
        nav.push(
          MaterialPageRoute(builder: (_) => const AppointmentScreen()),
        );
        break;
      case _FeedKind.patient:
        if ((item.patientId ?? '').isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(
                patient: PersonalPatientsModel(
                  patientId: item.patientId,
                  patientName: item.patientName ?? 'Patient',
                  patientImage: item.imageUrl ?? '',
                  status: 'active',
                ),
              ),
            ),
          );
        } else {
          nav.push(
            MaterialPageRoute(builder: (_) => const PatientsScreen()),
          );
        }
        break;
      case _FeedKind.secondOpinion:
        if ((item.secondOpinionId ?? '').isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => SecondOpinionDetailScreen(
                requestId: item.secondOpinionId!,
              ),
            ),
          );
        } else {
          nav.push(
            MaterialPageRoute(builder: (_) => const SecondOpinionsScreen()),
          );
        }
        break;
      case _FeedKind.prescription:
        nav.push(
          MaterialPageRoute(
            builder: (_) => PrescriptionsScreen(
              patient: (item.patientId ?? '').isEmpty
                  ? null
                  : PersonalPatientsModel(
                      patientId: item.patientId,
                      patientName: item.patientName ?? 'Patient',
                      patientImage: item.imageUrl ?? '',
                      status: 'active',
                    ),
            ),
          ),
        );
        break;
      case _FeedKind.labRequest:
        nav.push(
          MaterialPageRoute(
            builder: (_) => LabRequestsScreen(
              patient: (item.patientId ?? '').isEmpty
                  ? null
                  : PersonalPatientsModel(
                      patientId: item.patientId,
                      patientName: item.patientName ?? 'Patient',
                      patientImage: item.imageUrl ?? '',
                      status: 'active',
                    ),
            ),
          ),
        );
        break;
      case _FeedKind.clinicalNote:
        if ((item.patientId ?? '').isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(
                patient: PersonalPatientsModel(
                  patientId: item.patientId,
                  patientName: item.patientName ?? 'Patient',
                  patientImage: item.imageUrl ?? '',
                  status: 'active',
                ),
              ),
            ),
          );
        }
        break;
      case _FeedKind.general:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    return DoctorScaffold(
      title: 'Alerts',
      subtitle: 'Search and open what needs your attention',
      showBack: false,
      actions: doctorId == null
          ? null
          : [
              IconButton(
                tooltip: 'Mark all read',
                onPressed: () => _markAllRead(doctorId),
                icon: const Icon(Icons.done_all_rounded, size: 22),
              ),
            ],
      body: doctorId == null
          ? const DoctorEmptyState(
              icon: EneftyIcons.notification_outline,
              title: 'Sign in required',
              message: 'Sign in again to view your alerts.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: DoctorSearchField(
                    controller: _search,
                    hint: 'Search alerts…',
                    onChanged: (value) =>
                        setState(() => _query = value.trim()),
                  ),
                ),
                Expanded(
                  child: _DoctorFeedBody(
                    doctorId: doctorId,
                    query: _query,
                    onOpen: _openItem,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DoctorFeedBody extends StatelessWidget {
  const _DoctorFeedBody({
    required this.doctorId,
    required this.query,
    required this.onOpen,
  });

  final String doctorId;
  final String query;
  final ValueChanged<_FeedItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Notifications')
          .where('recipientId', isEqualTo: doctorId)
          .snapshots(),
      builder: (context, notifSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Appointments')
              .where('doctorId', isEqualTo: doctorId)
              .snapshots(),
          builder: (context, apptSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .doc(doctorId)
                  .collection('Patients')
                  .snapshots(),
              builder: (context, patientsSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Doctors')
                      .doc(doctorId)
                      .collection('SecondOpinions')
                      .snapshots(),
                  builder: (context, soSnap) {
                    final waiting = notifSnap.connectionState ==
                            ConnectionState.waiting &&
                        apptSnap.connectionState == ConnectionState.waiting &&
                        patientsSnap.connectionState ==
                            ConnectionState.waiting &&
                        soSnap.connectionState == ConnectionState.waiting;
                    if (waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      );
                    }

                    final items = <_FeedItem>[];

                    // 1) Server-side notifications
                    if (!notifSnap.hasError) {
                      for (final doc in notifSnap.data?.docs ?? []) {
                        items.add(_FeedItem.fromNotification(doc));
                      }
                    }

                    // 2) Recent appointments (activity)
                    if (!apptSnap.hasError) {
                      for (final doc in apptSnap.data?.docs ?? []) {
                        items.add(_FeedItem.fromAppointment(doc));
                      }
                    }

                    // 3) Patients who added / booked with this doctor
                    if (!patientsSnap.hasError) {
                      for (final doc in patientsSnap.data?.docs ?? []) {
                        items.add(_FeedItem.fromPatient(doc));
                      }
                    }

                    // 4) Second-opinion requests (even before FCM history)
                    if (!soSnap.hasError) {
                      for (final doc in soSnap.data?.docs ?? []) {
                        final status =
                            (doc.data()['status'] ?? '').toString().toLowerCase();
                        if (status == 'pending_payment') continue;
                        items.add(_FeedItem.fromSecondOpinion(doc));
                      }
                    }

                    // Dedupe by stable key. Prefer real Notifications docs
                    // over activity mirrors, then keep the newest.
                    final byKey = <String, _FeedItem>{};
                    for (final item in items) {
                      final existing = byKey[item.key];
                      if (existing == null) {
                        byKey[item.key] = item;
                        continue;
                      }
                      final itemIsNotif = item.notificationId != null;
                      final existingIsNotif = existing.notificationId != null;
                      if (itemIsNotif && !existingIsNotif) {
                        byKey[item.key] = item;
                      } else if (itemIsNotif == existingIsNotif &&
                          item.at.isAfter(existing.at)) {
                        byKey[item.key] = item;
                      }
                    }

                    final q = query.toLowerCase();
                    final feed = byKey.values.where((item) {
                      if (q.isEmpty) return true;
                      return '${item.title} ${item.body} ${item.patientName ?? ''}'
                          .toLowerCase()
                          .contains(q);
                    }).toList()
                      ..sort((a, b) => b.at.compareTo(a.at));

                    // Cap list for performance
                    final visible = feed.take(80).toList();

                    if (visible.isEmpty) {
                      return DoctorEmptyState(
                        icon: EneftyIcons.notification_outline,
                        title: query.isEmpty ? 'No alerts yet' : 'No matches',
                        message: query.isEmpty
                            ? 'New appointments, patients, messages, and second opinions will show up here.'
                            : 'No alerts match "$query".',
                      );
                    }

                    final unread = visible.where((i) => !i.read).length;

                    return RefreshIndicator(
                      color: DoctorUi.primary,
                      onRefresh: () async {
                        // Streams auto-refresh; short delay for pull UX.
                        await Future<void>.delayed(
                          const Duration(milliseconds: 400),
                        );
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: visible.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                unread == 0
                                    ? '${visible.length} update${visible.length == 1 ? '' : 's'}'
                                    : '$unread unread · ${visible.length} total',
                                style: TextStyle(
                                  color: DoctorUi.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          final item = visible[index - 1];
                          return _NotificationTile(
                            item: item,
                            onTap: () => onOpen(item),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

enum _FeedKind {
  appointment,
  patient,
  message,
  call,
  secondOpinion,
  prescription,
  labRequest,
  clinicalNote,
  general,
}

class _FeedItem {
  const _FeedItem({
    required this.key,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
    this.notificationId,
    this.patientId,
    this.patientName,
    this.imageUrl,
    this.secondOpinionId,
  });

  final String key;
  final _FeedKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? notificationId;
  final String? patientId;
  final String? patientName;
  final String? imageUrl;
  final String? secondOpinionId;

  factory _FeedItem.fromNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = (data['type'] ?? '').toString().toLowerCase();
    final kind = _kindFromType(type);
    final nested = data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : <String, dynamic>{};
    final patientId = (data['patientId'] ??
            nested['patientId'] ??
            nested['senderId'] ??
            '')
        .toString();
    final patientName = (data['patientName'] ??
            nested['patientName'] ??
            nested['senderName'] ??
            '')
        .toString();
    final image = (data['patientImage'] ??
            nested['patientImage'] ??
            nested['senderImage'] ??
            '')
        .toString();
    final sourceCollection = (data['sourceCollection'] ?? '').toString();
    final sourceId = (data['sourceId'] ?? nested['secondOpinionId'] ?? '')
        .toString();
    final secondOpinionId = (nested['secondOpinionId'] ??
            (sourceCollection == 'SecondOpinions' ? sourceId : ''))
        .toString();
    final key = secondOpinionId.isNotEmpty
        ? 'so_$secondOpinionId'
        : 'n_${doc.id}';

    return _FeedItem(
      key: key,
      kind: kind,
      title: data['title']?.toString() ?? 'Update',
      body: data['body']?.toString() ?? '',
      at: _ts(data['createdAt']),
      read: data['read'] == true,
      notificationId: doc.id,
      patientId: patientId.isEmpty ? null : patientId,
      patientName: patientName.isEmpty ? null : patientName,
      imageUrl: image.isEmpty ? null : image,
      secondOpinionId: secondOpinionId.isEmpty ? null : secondOpinionId,
    );
  }

  factory _FeedItem.fromSecondOpinion(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['patientName'] ??
            data['patient_name'] ??
            'A patient')
        .toString();
    final status = (data['status'] ?? 'pending').toString();
    final concern =
        (data['concern'] ?? data['patientQuestion'] ?? '').toString();
    final urgency = (data['urgency'] ?? '').toString();
    final bodyParts = <String>[
      if (concern.isNotEmpty) concern,
      if (urgency.toLowerCase() == 'urgent') 'Urgent',
      status,
    ];

    return _FeedItem(
      key: 'so_${doc.id}',
      kind: _FeedKind.secondOpinion,
      title: urgency.toLowerCase() == 'urgent'
          ? 'Urgent second opinion'
          : 'Second opinion request',
      body: bodyParts.join(' · '),
      at: _ts(data['createdAt'] ?? data['updatedAt']),
      read: true,
      secondOpinionId: doc.id,
      patientId: (data['patientId'] ?? data['patient_id'])?.toString(),
      patientName: name,
      imageUrl: (data['patientImage'] ?? data['patient_image'])?.toString(),
    );
  }

  factory _FeedItem.fromAppointment(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final patient = data['patient'] is Map
        ? Map<String, dynamic>.from(data['patient'] as Map)
        : <String, dynamic>{};
    final name = (patient['name'] ??
            data['patient_name'] ??
            data['patientName'] ??
            'A patient')
        .toString();
    final status = (data['status'] ?? 'pending').toString();
    final purpose =
        (data['purpose'] ?? data['type'] ?? 'appointment').toString();
    final at = _ts(
      data['createdAt'] ?? data['date_created'] ?? data['startAt'] ?? data['date'],
    );

    return _FeedItem(
      key: 'a_${doc.id}',
      kind: _FeedKind.appointment,
      title: 'New appointment',
      body: '$name · $purpose · $status',
      at: at,
      read: true, // activity items don't have read state
      patientId: (data['patientId'] ?? data['patient_id'] ?? patient['id'])
          ?.toString(),
      patientName: name,
      imageUrl: (patient['photo'] ?? data['patient_image'])?.toString(),
    );
  }

  factory _FeedItem.fromPatient(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name =
        (data['patientName'] ?? data['name'] ?? 'A patient').toString();
    final source = (data['source'] ?? 'patient').toString().replaceAll('_', ' ');
    final at = _ts(data['createdAt'] ?? data['updatedAt']);

    return _FeedItem(
      key: 'p_${doc.id}',
      kind: _FeedKind.patient,
      title: 'New patient',
      body: '$name joined your list · $source',
      at: at,
      read: true,
      patientId: (data['patientId'] ?? doc.id).toString(),
      patientName: name,
      imageUrl: (data['patientImage'] ?? data['photo'])?.toString(),
    );
  }

  static _FeedKind _kindFromType(String type) {
    if (type.contains('call')) {
      return _FeedKind.call;
    }
    if (type.contains('appointment') || type.contains('booking')) {
      return _FeedKind.appointment;
    }
    if (type.contains('message') ||
        type.contains('chat') ||
        type.contains('conversation')) {
      return _FeedKind.message;
    }
    if (type.contains('second') || type.contains('opinion')) {
      return _FeedKind.secondOpinion;
    }
    if (type.contains('prescription')) {
      return _FeedKind.prescription;
    }
    if (type.contains('lab_request') ||
        (type.contains('lab') && !type.contains('report'))) {
      return _FeedKind.labRequest;
    }
    if (type.contains('clinical_note') ||
        type.contains('recommendation') ||
        type.contains('care_note')) {
      return _FeedKind.clinicalNote;
    }
    if (type.contains('patient')) {
      return _FeedKind.patient;
    }
    return _FeedKind.general;
  }

  static DateTime _ts(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final _FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final icon = switch (item.kind) {
      _FeedKind.appointment => EneftyIcons.calendar_2_outline,
      _FeedKind.patient => EneftyIcons.profile_2user_outline,
      _FeedKind.message => EneftyIcons.message_2_outline,
      _FeedKind.call => Icons.call_rounded,
      _FeedKind.secondOpinion => EneftyIcons.document_text_outline,
      _FeedKind.prescription => Icons.medication_outlined,
      _FeedKind.labRequest => Icons.science_outlined,
      _FeedKind.clinicalNote => EneftyIcons.note_2_outline,
      _FeedKind.general => EneftyIcons.notification_outline,
    };
    final accent = switch (item.kind) {
      _FeedKind.appointment => Colors.blue,
      _FeedKind.patient => Colors.purple,
      _FeedKind.message => Colors.teal,
      _FeedKind.call => Colors.green,
      _FeedKind.secondOpinion => Colors.orange,
      _FeedKind.prescription => Colors.teal,
      _FeedKind.labRequest => Colors.deepOrange,
      _FeedKind.clinicalNote => Colors.indigo,
      _FeedKind.general => DoctorUi.primary,
    };

    return DoctorCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: item.read ? null : DoctorUi.primary.withValues(alpha: .06),
      borderColor:
          item.read ? null : DoctorUi.primary.withValues(alpha: .28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              if (!item.read)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DoctorUi.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: DoctorUi.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight:
                              item.read ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relative(item.at),
                      style: theme.bodySmall?.copyWith(
                        color: DoctorUi.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(
                      color: DoctorUi.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime at) {
    if (at.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24 && now.day == at.day) {
      return DateFormat.jm().format(at);
    }
    if (diff.inDays < 7) return DateFormat.E().format(at);
    return DateFormat.MMMd().format(at);
  }
}
