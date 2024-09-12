import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/components/bottombar.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';

class BaseScreen extends ConsumerStatefulWidget {
  const BaseScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(EneftyIcons.message_outline),
      ),
      body: YarisaConstants.basePages.elementAt(selectedIndex),
      bottomNavigationBar: BottomBar(
          index: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          showAllTitles: true,
          curveRadius: 0,
          items: const [
            BottomBarItem(
                icon: Icon(EneftyIcons.home_outline),
                activeIcon: Icon(EneftyIcons.home_bold),
                title: Text("Home")),
            BottomBarItem(
                icon: Icon(EneftyIcons.calendar_2_outline),
                activeIcon: Icon(EneftyIcons.calendar_2_bold),
                title: Text("Appointments")),
            BottomBarItem(
                icon: Icon(EneftyIcons.tick_circle_outline),
                activeIcon: Icon(EneftyIcons.tick_circle_bold),
                title: Text("Availabilty")),
            BottomBarItem(
                icon: Icon(EneftyIcons.profile_2user_outline),
                activeIcon: Icon(EneftyIcons.profile_2user_bold),
                title: Text("Patients")),
            // BottomBarItem(
            //     icon: Icon(EneftyIcons.more_outline),
            //     activeIcon: Icon(EneftyIcons.more_bold),
            //     title: Text("More"))
          ]),
    );
  }
}
