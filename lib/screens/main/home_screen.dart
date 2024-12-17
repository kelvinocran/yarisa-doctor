import 'package:cached_network_image/cached_network_image.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:yarisa_doctor/api/api_methods.dart';

import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/add_prescription.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';

import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(apimethods);
    return Scaffold(
      body: Column(
        children: [
          yarisaAppBar(context,
              autoShowBackButton: false,
              title: AppStrings.home,
              titleWidget: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: user.userAccount?.pic != null ||
                            user.userAccount?.pic != ""
                        ? CachedNetworkImageProvider("${user.userAccount?.pic}")
                        : null,
                  ),
                  15.wgap,
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        YarisaText(
                          text: greeting(),
                          type: TextType.bodySmall,
                          color: Colors.grey,
                        ),
                        YarisaText(
                          text: "${user.userAccount?.fullname}",
                          type: TextType.bodyBig,
                          weight: FontWeight.w600,
                        ),
                      ]),
                ],
              )),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FormTextField(
                  //   controller: TextEditingController(),
                  //   hint: "Search",
                  //   radius: 100,
                  //   labeled: false,
                  //   iconSize: 20,
                  //   icon: EneftyIcons.search_normal_2_outline,
                  // ),
                  // 20.hgap,
                  const UpcomingAppointments(),
                  ResponsiveGridList(
                      horizontalGridSpacing: 10,
                      verticalGridSpacing: 10,
                      minItemWidth: MediaQuery.of(context).size.width / 2,
                      minItemsPerRow: 2,
                      maxItemsPerRow: 4,
                      listViewBuilderOptions: ListViewBuilderOptions(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero),
                      children: List.generate(
                        list.length,
                        (index) => HomeDashboardItem(data: list[index]),
                      ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final list = [
  {
    "title": "My Patients",
    "description": "You currently have 6 patients",
    "icon": EneftyIcons.profile_2user_bold,
    "color": Colors.purple.shade300,
    'slug': 'patients'
  },
  {
    "title": "Appointments",
    "description": "You have 2 upcoming appointments",
    "icon": EneftyIcons.calendar_2_bold,
    "color": Colors.blue.shade300,
    'slug': 'appointments'
  },
  {
    "title": "Prescriptions",
    "description": "Find all prescriptions here.",
    "icon": EneftyIcons.health_bold,
    "color": Colors.amber.shade300,
    'slug': 'prescriptions'
  },
  {
    "title": "Laboratories",
    "description": "Get access to laboratories",
    "icon": EneftyIcons.bucket_bold,
    "color": Colors.green.shade300,
    'slug': 'labs'
  }
];

class HomeDashboardItem extends StatelessWidget {
  const HomeDashboardItem({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (data['slug']) {
          case 'patients':
            Get.to(() => const PatientsScreen());
            break;
          case 'labs':
            Get.to(() => const PatientsScreen());
            break;
          case 'prescriptions':
            Get.to(() => const AddPrescription());
            break;
          case 'appointments':
            Get.to(() => const AppointmentScreen());
            break;
        }
      },
      splashColor: data['color'].withOpacity(.2),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
            color: data['color'].withOpacity(.1),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: data['color'].withOpacity(.2),
                child: Icon(
                  data['icon'],
                  color: data['color'],
                )),
            10.hgap,
            YarisaText(
              text: data['title'],
              type: TextType.bodyBig,
              spacing: 0,
              size: 18,
              weight: FontWeight.w600,
            ),
            5.hgap,
            YarisaText(
              lines: 3,
              text: data['description'],
              type: TextType.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
