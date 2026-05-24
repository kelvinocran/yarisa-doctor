import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/skeleton_loader.dart';

enum _AvailabilityViewMode { calendar, list }

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool status = false;
  bool scheduleLoading = true;
  List<String> availability = [];
  Map<String, dynamic>? data;
  List<AvailabilityDaySummary> schedule = [];
  DateTime selectedDate = _dateOnly(DateTime.now());
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _AvailabilityViewMode viewMode = _AvailabilityViewMode.calendar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSchedule();
      if (!mounted) return;
      await _loadSelectedDay(selectedDate);
    });
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    setState(() => scheduleLoading = true);
    final days = await ref.read(apimethods).getAvailabilitySchedule();
    if (!mounted) return;
    setState(() {
      schedule = days;
      scheduleLoading = false;
    });
  }

  Future<void> _loadSelectedDay(DateTime date) async {
    if (!mounted) return;
    await ref.read(apimethods).getAvailability(
          date: _dateOnly(date),
          onSuccess: _applySelectedDayData,
          onFailed: () {
            if (!mounted) return;
            setState(() {
              data = null;
              status = false;
              availability = [];
            });
          },
        );
  }

  void _applySelectedDayData(Map<String, dynamic>? value) {
    if (!mounted) return;
    setState(() {
      data = value;
      status = value?["status"] == true;
      availability = List<dynamic>.from(value?["slots"] ?? [])
          .map((slot) => slot.toString())
          .where((slot) => slot.trim().isNotEmpty)
          .toList();
    });
  }

  void _showVerificationRequired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your doctor account must be verified before you can publish availability.',
        ),
      ),
    );
  }

  Future<void> _selectDate(DateTime date) async {
    final day = _dateOnly(date);
    setState(() {
      selectedDate = day;
      visibleMonth = DateTime(day.year, day.month);
      status = false;
      availability = [];
    });
    await _loadSelectedDay(day);
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => status = value);
    await ref.read(apimethods).updateAvailability(
          date: selectedDate,
          timeSlots: "",
          status: value,
          onSuccess: (value) async {
            _applySelectedDayData(value);
            await _loadSchedule();
          },
          onFailed: () {
            _applySelectedDayData(data);
            _showVerificationRequired();
          },
        );
  }

  Future<void> _removeSlot(String slot) async {
    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: "Delete slot?",
      message:
          "Remove $slot from ${DateFormat.yMMMMEEEEd().format(selectedDate)}?",
      confirmLabel: "Delete",
      icon: EneftyIcons.trash_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await ref.read(apimethods).removeTimeSlot(
          date: selectedDate,
          timeSlots: slot,
          onSuccess: (value) async {
            _applySelectedDayData(value);
            await _loadSchedule();
          },
        );
  }

  Future<void> _showAddSlotSheet() async {
    final startTime = TextEditingController();
    final endTime = TextEditingController();
    var sheetStatus = status || availability.isNotEmpty;
    var saving = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickTime(TextEditingController controller) async {
              final value = await showTimePicker(
                context: sheetContext,
                initialTime: TimeOfDay.now(),
              );
              if (value == null || !sheetContext.mounted) return;
              controller.text = value.format(sheetContext);
              setSheetState(() {});
            }

            Future<void> save() async {
              if (saving) return;
              if (!mounted) return;
              final slot = startTime.text.isEmpty && endTime.text.isEmpty
                  ? ""
                  : "${startTime.text} - ${endTime.text}";
              setSheetState(() => saving = true);
              try {
                var saved = false;
                await ref.read(apimethods).updateAvailability(
                      date: selectedDate,
                      timeSlots: slot,
                      status: sheetStatus || slot.isNotEmpty,
                      onSuccess: (value) async {
                        saved = true;
                        _applySelectedDayData(value);
                        await _loadSchedule();
                      },
                      onFailed: _showVerificationRequired,
                    );
                if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: YarisaText(
                            text: DateFormat.yMMMMEEEEd().format(selectedDate),
                            type: TextType.bodyBig,
                            weight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        )
                      ],
                    ),
                    12.hgap,
                    SwitchListTile(
                      value: sheetStatus,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      title: Text(
                        AppStrings.manageavailabilty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        AppStrings.toggleyouravailability,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onChanged: (value) {
                        setSheetState(() => sheetStatus = value);
                      },
                    ),
                    12.hgap,
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => pickTime(startTime),
                            child: FormTextField(
                              endicon: const Icon(
                                EneftyIcons.clock_2_outline,
                                size: 18,
                              ),
                              enabled: false,
                              controller: startTime,
                              hint: AppStrings.starttime,
                            ),
                          ),
                        ),
                        10.wgap,
                        Expanded(
                          child: InkWell(
                            onTap: () => pickTime(endTime),
                            child: FormTextField(
                              endicon: const Icon(
                                EneftyIcons.clock_2_outline,
                                size: 18,
                              ),
                              enabled: false,
                              controller: endTime,
                              hint: AppStrings.endtime,
                            ),
                          ),
                        ),
                      ],
                    ),
                    20.hgap,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              startTime.clear();
                              endTime.clear();
                              setSheetState(() {});
                            },
                            child: const Text(AppStrings.cancel),
                          ),
                        ),
                        10.wgap,
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving ? null : save,
                            child: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(AppStrings.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      startTime.dispose();
      endTime.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(apimethods).loading;
    return Scaffold(
      appBar: yarisaAppBar(
        context,
        title: AppStrings.availability,
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddSlotSheet,
        child: const Icon(Icons.add, size: 20),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<_AvailabilityViewMode>(
                segments: const [
                  ButtonSegment(
                    value: _AvailabilityViewMode.calendar,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text("Calendar"),
                  ),
                  ButtonSegment(
                    value: _AvailabilityViewMode.list,
                    icon: Icon(Icons.view_agenda_outlined),
                    label: Text("List"),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (value) {
                  setState(() => viewMode = value.first);
                },
              ),
              20.hgap,
              if (scheduleLoading)
                const ScheduleSkeleton().paddingSymmetric(vertical: 10)
              else if (viewMode == _AvailabilityViewMode.calendar)
                _AvailabilityCalendar(
                  visibleMonth: visibleMonth,
                  selectedDate: selectedDate,
                  schedule: schedule,
                  onMonthChanged: (month) {
                    setState(() => visibleMonth = month);
                  },
                  onDateSelected: _selectDate,
                )
              else
                _AvailabilityList(
                  schedule: schedule,
                  selectedDate: selectedDate,
                  onDateSelected: _selectDate,
                ),
              20.hgap,
              _SelectedDaySlots(
                date: selectedDate,
                loading: loading,
                status: status,
                slots: availability,
                onStatusChanged: _toggleStatus,
                onRemoveSlot: _removeSlot,
                onAddSlot: _showAddSlotSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCalendar extends StatelessWidget {
  const _AvailabilityCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.schedule,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<AvailabilityDaySummary> schedule;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final days = _calendarCells(monthStart);
    final scheduleByKey = {
      for (final day in schedule) day.dateKey: day,
    };

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(visibleMonth.year, visibleMonth.month - 1),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: YarisaText(
                  text: DateFormat.yMMMM().format(visibleMonth),
                  type: TextType.bodyBig,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(visibleMonth.year, visibleMonth.month + 1),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        8.hgap,
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: const [
            _WeekdayLabel("M"),
            _WeekdayLabel("T"),
            _WeekdayLabel("W"),
            _WeekdayLabel("T"),
            _WeekdayLabel("F"),
            _WeekdayLabel("S"),
            _WeekdayLabel("S"),
          ],
        ),
        GridView.builder(
          itemCount: days.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: .9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final date = days[index];
            if (date == null) return const SizedBox.shrink();

            final key = _scheduleKey(date);
            final day = scheduleByKey[key];
            final selected = _isSameDay(date, selectedDate);
            return _CalendarDayCell(
              date: date,
              selected: selected,
              day: day,
              onTap: () => onDateSelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  const _AvailabilityList({
    required this.schedule,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<AvailabilityDaySummary> schedule;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final openDays = schedule.where((day) => day.hasOpenSlots).toList();
    if (openDays.isEmpty) {
      return _EmptyAvailabilityCard(
        title: "No open slots",
        action: TextButton.icon(
          onPressed: () => onDateSelected(DateTime.now()),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Select today"),
        ),
      );
    }

    return Column(
      children: openDays.map((day) {
        final selected = _isSameDay(day.date, selectedDate);
        return _AvailabilityDayCard(
          day: day,
          selected: selected,
          onTap: () => onDateSelected(day.date),
        );
      }).toList(),
    );
  }
}

class _SelectedDaySlots extends StatelessWidget {
  const _SelectedDaySlots({
    required this.date,
    required this.loading,
    required this.status,
    required this.slots,
    required this.onStatusChanged,
    required this.onRemoveSlot,
    required this.onAddSlot,
  });

  final DateTime date;
  final bool loading;
  final bool status;
  final List<String> slots;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<String> onRemoveSlot;
  final VoidCallback onAddSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YarisaText(
                      text: DateFormat.yMMMMEEEEd().format(date),
                      type: TextType.bodyBig,
                      weight: FontWeight.w700,
                    ),
                    YarisaText(
                      text: status ? "Open" : "Closed",
                      type: TextType.subtitle,
                      color: status ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ),
              Switch(value: status, onChanged: onStatusChanged),
            ],
          ),
          16.hgap,
          if (loading)
            const SkeletonBox(
              height: 76,
              width: double.infinity,
              radius: 16,
            ).paddingSymmetric(vertical: 6)
          else if (slots.isEmpty)
            _EmptyAvailabilityCard(
              title: "No slots on this day",
              action: TextButton.icon(
                onPressed: onAddSlot,
                icon: const Icon(Icons.add),
                label: const Text(""),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots
                  .map((slot) => InputChip(
                        label: Text(slot),
                        deleteIcon: const Icon(EneftyIcons.trash_outline),
                        onDeleted: () => onRemoveSlot(slot),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityDayCard extends StatelessWidget {
  const _AvailabilityDayCard({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final AvailabilityDaySummary day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: .08)
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: .18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: YarisaText(
                    text: DateFormat.yMMMMEEEEd().format(day.date),
                    type: TextType.bodyBig,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  "${day.slots.length} slot${day.slots.length == 1 ? '' : 's'}",
                ),
              ],
            ),
            10.hgap,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  day.slots.map((slot) => Chip(label: Text(slot))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.selected,
    required this.day,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final AvailabilityDaySummary? day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOpenSlots = day?.hasOpenSlots == true;
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? primary : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary
                : hasOpenSlots
                    ? Colors.green.withValues(alpha: .65)
                    : Colors.grey.withValues(alpha: .18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.d().format(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : null,
                  ),
            ),
            5.hgap,
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 6,
              width: hasOpenSlots ? 18 : 6,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : hasOpenSlots
                        ? Colors.green
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyAvailabilityCard extends StatelessWidget {
  const _EmptyAvailabilityCard({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            color: Colors.grey.shade500,
          ),
          8.hgap,
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[12.hgap, action!],
        ],
      ),
    );
  }
}

List<DateTime?> _calendarCells(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final leadingEmptyCells = firstDay.weekday - 1;
  final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
  return [
    ...List<DateTime?>.filled(leadingEmptyCells, null),
    ...List.generate(
      totalDays,
      (index) => DateTime(month.year, month.month, index + 1),
    ),
  ];
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _scheduleKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
