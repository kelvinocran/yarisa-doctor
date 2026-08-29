import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/components/bottombar.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/services/deep_link_router.dart';
import 'package:yarisa_doctor/services/presence_service.dart';
import 'package:yarisa_doctor/widgets/nav_badge.dart';

class BaseScreen extends ConsumerStatefulWidget {
  const BaseScreen({super.key});

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  int selectedIndex = 0;

  bool get _showChatFab => selectedIndex != 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PresenceService.instance.loadToggle();
      PresenceService.instance.attach();
      DeepLinkRouter.markReady();
    });
  }

  @override
  void dispose() {
    PresenceService.instance.detach();
    super.dispose();
  }

  Stream<int> _unreadChatCount(String uid) {
    return FirebaseFirestore.instance
        .collection('Messages')
        .doc(uid)
        .collection('messages')
        .snapshots()
        .map((snap) {
      var total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['unread'] == true) {
          final c = data['unreadCount'];
          if (c is int && c > 0) {
            total += c;
          } else {
            total += 1;
          }
        }
      }
      return total;
    });
  }

  Stream<int> _unreadAlertCount(String uid) {
    return FirebaseFirestore.instance
        .collection('Notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.where((d) => d.data()['read'] != true).length);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<int>(
      stream: uid == null ? null : _unreadChatCount(uid),
      builder: (context, chatSnap) {
        final chatUnread = chatSnap.data ?? 0;
        return StreamBuilder<int>(
          stream: uid == null ? null : _unreadAlertCount(uid),
          builder: (context, alertSnap) {
            final alertUnread = alertSnap.data ?? 0;
            return Scaffold(
              floatingActionButton: _showChatFab
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DoctorChatInboxScreen(),
                          ),
                        );
                      },
                      child: NavBadgeIcon(
                        icon: EneftyIcons.message_outline,
                        count: chatUnread,
                      ),
                    )
                  : null,
              body: YarisaConstants.basePages.elementAt(selectedIndex),
              bottomNavigationBar: BottomBar(
                index: selectedIndex,
                onTap: (index) {
                  setState(() => selectedIndex = index);
                },
                showAllTitles: false,
                showTitle: false,
                curveRadius: 0,
                items: [
                  const BottomBarItem(
                    icon: Icon(EneftyIcons.home_outline),
                    activeIcon: Icon(EneftyIcons.home_bold),
                    title: Text('Home'),
                  ),
                  const BottomBarItem(
                    icon: Icon(EneftyIcons.calendar_2_outline),
                    activeIcon: Icon(EneftyIcons.calendar_2_bold),
                    title: Text('Appointments'),
                  ),
                  const BottomBarItem(
                    icon: Icon(EneftyIcons.tick_circle_outline),
                    activeIcon: Icon(EneftyIcons.tick_circle_bold),
                    title: Text('Availability'),
                  ),
                  const BottomBarItem(
                    icon: Icon(EneftyIcons.profile_2user_outline),
                    activeIcon: Icon(EneftyIcons.profile_2user_bold),
                    title: Text('Patients'),
                  ),
                  BottomBarItem(
                    icon: NavBadgeIcon(
                      icon: EneftyIcons.notification_outline,
                      count: alertUnread,
                    ),
                    activeIcon: NavBadgeIcon(
                      icon: EneftyIcons.notification_bold,
                      count: alertUnread,
                      active: true,
                    ),
                    title: const Text('Alerts'),
                  ),
                  const BottomBarItem(
                    icon: Icon(EneftyIcons.setting_2_outline),
                    activeIcon: Icon(EneftyIcons.setting_2_bold),
                    title: Text('Profile'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
