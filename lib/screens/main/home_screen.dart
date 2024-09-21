import 'package:cached_network_image/cached_network_image.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_carousel/flutter_custom_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

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
    return Scaffold(
      body: Column(
        children: [
          yarisaAppBar(context,
              autoShowBackButton: false,
              title: AppStrings.home,
              titleWidget: Row(
                children: [
                  const CircleAvatar(),
                  15.wgap,
                  const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        YarisaText(
                          text: AppStrings.night,
                          type: TextType.bodySmall,
                          // spacing: 0,
                          color: Colors.grey,
                        ),
                        YarisaText(
                          text: "Dr. Michael",
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
                  FormTextField(
                    controller: TextEditingController(),
                    hint: "Search",
                    radius: 100,
                    labeled: false,
                    iconSize: 20,
                    icon: EneftyIcons.search_normal_2_outline,
                  ),
                  20.hgap,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const YarisaText(
                        text: "Upcoming Appointments",
                        type: TextType.bodyBig,
                        spacing: 0,
                        weight: FontWeight.w500,
                      ),
                      TextButton(onPressed: () {}, child: const Text("See All"))
                    ],
                  ),
                  10.hgap,
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.separated(
                      separatorBuilder: (context, index) => 10.wgap,
                      itemCount: 5,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 118, 34, 135),
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 26,
                                    backgroundImage: CachedNetworkImageProvider(
                                        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d"),
                                  ),
                                  15.wgap,
                                  const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        YarisaText(
                                          text: "Michael Jordan",
                                          type: TextType.bodyBig,
                                          color: Colors.white,
                                          spacing: 0,
                                          weight: FontWeight.w600,
                                        ),
                                        YarisaText(
                                          text: AppStrings.night,
                                          type: TextType.bodySmall,
                                          // spacing: 0,
                                          color: Colors.white,
                                        ),
                                      ]),
                                  const Spacer(),
                                  const CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        EneftyIcons.call_bold,
                                        size: 20,
                                        color:
                                            Color.fromARGB(255, 118, 34, 135),
                                      ))
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 18),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        const Color.fromARGB(255, 91, 26, 104)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            EneftyIcons.calendar_2_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          5.wgap,
                                          const Expanded(
                                            child: YarisaText(
                                              text: "Monday, 26 September",
                                              type: TextType.subtitle,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    10.wgap,
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Icon(
                                            EneftyIcons.clock_2_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          5.wgap,
                                          const Flexible(
                                            child: YarisaText(
                                              text: "10:00 am",
                                              type: TextType.subtitle,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  30.hgap,
                  ResponsiveGridList(
                      horizontalGridSpacing:
                          10, // Horizontal space between grid items
                      verticalGridSpacing:
                          10, // Vertical space between grid items

                      minItemWidth: MediaQuery.of(context).size.width /
                          2, // The minimum item width (can be smaller, if the layout constraints are smaller)
                      minItemsPerRow:
                          2, // The minimum items to show in a single row. Takes precedence over minItemWidth
                      maxItemsPerRow:
                          4, // The maximum items to show in a single row. Can be useful on large screens
                      listViewBuilderOptions: ListViewBuilderOptions(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero),
                      children: List.generate(
                        4,
                        (index) => Container(
                          padding: const EdgeInsets.all(20),
                          height: 200,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey.withOpacity(.3),
                                  child: Icon(
                                    EneftyIcons.profile_2user_bold,
                                    color: Colors.purple.shade300,
                                  )),
                              10.hgap,
                              const YarisaText(
                                text: "Patients",
                                type: TextType.bodyBig,
                                spacing: 0,
                                size: 18,
                                weight: FontWeight.w600,
                              ),
                              const YarisaText(
                                lines: 3,
                                text: "You currently have 6 patients",
                                type: TextType.subtitle,
                              ),
                              1.hgap,
                              const Spacer(),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.navigate_next),
                              )
                            ],
                          ),
                        ),
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
