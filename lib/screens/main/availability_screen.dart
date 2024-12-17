import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yarisa_doctor/api/api_methods.dart';

import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final startTime = TextEditingController();
  final endTime = TextEditingController();

  bool status = false;

  List<dynamic> availability = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? data;
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(apimethods).getAvailability(
            date: selectedDate,
            onSuccess: (p0) {
              if (p0 != null) {
                data = p0;
                status = p0["status"];
                availability = p0["slots"];
              } else {
                data = null;
                status = false;
                availability = [];
              }
              setState(() {});
            },
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(apimethods).loading;
    return Scaffold(
      appBar: yarisaAppBar(
        context,
        title: AppStrings.availability,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: CalendarTimeline(
              initialDate: selectedDate,
              firstDate: DateTime(2024, 1),
              lastDate: DateTime(DateTime.now().year, 13),
              onDateSelected: (date) async {
                if (!loading) {
                  setState(() {
                    status = false;
                    selectedDate = DateTime(date.year, date.month, date.day);
                  });

                  await ref.read(apimethods).getAvailability(
                        date: selectedDate,
                        onSuccess: (p0) {
                          if (p0 != null) {
                            data = p0;
                            status = p0["status"];
                            availability = p0["slots"];
                          } else {
                            data = null;
                            status = false;
                            availability = [];
                          }
                          setState(() {});
                        },
                      );
                }
              },
              leftMargin: 20,
              monthColor: Colors.grey,
              dayColor: Colors.grey,
              activeDayColor: Colors.white,
              activeBackgroundDayColor: Theme.of(context).primaryColor,
            ),
          ),
          10.hgap,
          Divider(
            color: Colors.grey.withOpacity(.2),
          ),
          Expanded(
            child: loading
                ? const Loader()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            tileColor: Colors.transparent,
                            value: status,
                            title: Text(
                              AppStrings.manageavailabilty,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              AppStrings.toggleyouravailability,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onChanged: (value) async {
                              status = value;
                              setState(() {});
                              await ref.read(apimethods).updateAvailability(
                                    date: selectedDate,
                                    timeSlots: "",
                                    status: status,
                                    onSuccess: (p0) async {
                                      if (p0 != null) {
                                        data = p0;
                                        status = p0["status"];
                                        availability = p0["slots"];
                                      }
                                      setState(() {});
                                    },
                                  );
                            }),
                        15.hgap,
                        Text(
                          AppStrings.slots,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 18),
                        ),
                        10.hgap,
                        ListView.separated(
                            separatorBuilder: (context, index) => 10.hgap,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: availability.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final slot = availability[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  slot,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                trailing: InkWell(
                                    borderRadius: BorderRadius.circular(100),
                                    onTap: () async {
                                      await ref.read(apimethods).removeTimeSlot(
                                            date: selectedDate,
                                            timeSlots: slot,
                                            onSuccess: (p0) async {
                                              if (p0 != null) {
                                                data = p0;
                                                status = p0["status"];
                                                availability = p0["slots"];
                                              }
                                              setState(() {});
                                            },
                                          );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        EneftyIcons.trash_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    )),
                              );
                            }),
                      ],
                    ),
                  ),
          ),
          Divider(
            color: Colors.grey.withOpacity(.2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: InkWell(
                      onTap: () {
                        showTimePicker(
                                context: context, initialTime: TimeOfDay.now())
                            .then((value) {
                          if (value != null) {
                            // ignore: use_build_context_synchronously
                            startTime.text = value.format(context);
                            setState(() {});
                          }
                        });
                      },
                      child: FormTextField(
                          endicon: const Icon(
                            EneftyIcons.clock_2_outline,
                            size: 18,
                          ),
                          enabled: false,
                          controller: startTime,
                          hint: AppStrings.starttime),
                    )),
                    10.wgap,
                    Expanded(
                        child: InkWell(
                      onTap: () {
                        showTimePicker(
                                context: context, initialTime: TimeOfDay.now())
                            .then((value) {
                          if (value != null) {
                            // ignore: use_build_context_synchronously
                            endTime.text = value.format(context);
                            setState(() {});
                          }
                        });
                      },
                      child: FormTextField(
                          endicon: const Icon(
                            EneftyIcons.clock_2_outline,
                            size: 18,
                          ),
                          enabled: false,
                          controller: endTime,
                          hint: AppStrings.endtime),
                    ))
                  ],
                ),
                20.hgap,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          style: ButtonStyle(
                            padding: const WidgetStatePropertyAll(
                                EdgeInsets.all(15)),
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                          ),
                          onPressed: () {
                            endTime.clear();
                            startTime.clear();
                            setState(() {});
                          },
                          child: const Text(AppStrings.cancel)),
                    ),
                    10.wgap,
                    Expanded(
                      child: ElevatedButton(
                          onPressed: () async {
                            await ref.read(apimethods).updateAvailability(
                                  date: selectedDate,
                                  timeSlots: (endTime.text.isEmpty &&
                                          startTime.text.isEmpty)
                                      ? ""
                                      : "${startTime.text} - ${endTime.text}",
                                  status: status,
                                  onSuccess: (p0) async {
                                    if (p0 != null) {
                                      data = p0;
                                      status = p0["status"];
                                      availability = p0["slots"];
                                    } else {
                                      data = null;
                                      status = false;
                                      availability = [];
                                    }
                                    setState(() {});
                                  },
                                );

                            endTime.clear();

                            startTime.clear();
                            setState(() {});
                          },
                          child: const Text(AppStrings.save)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
