import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/availability/add_slot_sheet.dart';
import 'package:yarisa_doctor/components/availability/availability_widgets.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/confirmation_dialog.dart';
import 'package:yarisa_doctor/widgets/skeleton_loader.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool status = false;
  bool scheduleLoading = true;
  /// Open labels only (legacy helpers / overlap checks).
  List<String> availability = [];
  /// All slots for selected day, ascending (open + booked).
  List<DoctorAvailabilitySlot> daySlots = [];
  Map<String, dynamic>? data;
  List<AvailabilityDaySummary> schedule = [];
  DateTime selectedDate = availabilityDateOnly(DateTime.now());
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AvailabilityViewMode viewMode = AvailabilityViewMode.calendar;

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
          date: availabilityDateOnly(date),
          onSuccess: _applySelectedDayData,
          onFailed: () {
            if (!mounted) return;
            setState(() {
              data = null;
              status = false;
              availability = [];
              daySlots = [];
            });
          },
        );
  }

  void _applySelectedDayData(Map<String, dynamic>? value) {
    if (!mounted) return;
    final detailsRaw = value?['slotDetails'];
    List<DoctorAvailabilitySlot> details = [];
    if (detailsRaw is List) {
      details = detailsRaw.whereType<DoctorAvailabilitySlot>().toList()
        ..sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    }
    final openLabels = List<dynamic>.from(value?['slots'] ?? [])
        .map((slot) => slot.toString())
        .where((slot) => slot.trim().isNotEmpty)
        .toList()
      ..sort(compareSlotLabelsAscending);

    // If API only returned labels, still show them sorted.
    if (details.isEmpty && openLabels.isNotEmpty) {
      details = openLabels
          .map(
            (l) => DoctorAvailabilitySlot(
              label: l,
              open: true,
              booked: false,
            ),
          )
          .toList();
    }

    setState(() {
      data = value;
      status = value?['status'] == true;
      availability = openLabels;
      daySlots = details;
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
    final day = availabilityDateOnly(date);
    setState(() {
      selectedDate = day;
      visibleMonth = DateTime(day.year, day.month);
      status = false;
      availability = [];
      daySlots = [];
    });
    await _loadSelectedDay(day);
  }

  Future<void> _onBookedSlotTap(DoctorAvailabilitySlot slot) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DoctorUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              ListTile(
                leading: Icon(Icons.lock_outline, color: DoctorUi.primary),
                title: Text(slot.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('This time is held by a patient booking'),
              ),
              ListTile(
                leading: const Icon(EneftyIcons.calendar_2_outline),
                title: const Text('View appointments'),
                subtitle: const Text('Approve, reschedule, or manage bookings'),
                onTap: () => Navigator.pop(ctx, 'appointments'),
              ),
              ListTile(
                leading: Icon(Icons.event_available_outlined,
                    color: Colors.green.shade700),
                title: const Text('Cancel booking & free slot'),
                subtitle: const Text(
                    'Marks the appointment cancelled and reopens this time'),
                onTap: () => Navigator.pop(ctx, 'free'),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Keep as booked'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'appointments') {
      Get.to(() => const AppointmentScreen());
      return;
    }
    if (choice == 'free') {
      final ok = await showYarisaConfirmationDialog(
        context,
        title: 'Cancel booking & free slot?',
        message:
            'This will cancel the patient appointment for ${slot.label} and open the slot again for others. The patient should be notified outside the app if needed.',
        confirmLabel: 'Cancel & free',
        icon: Icons.event_available_outlined,
        isDestructive: true,
      );
      if (!ok || !mounted) return;
      await ref.read(apimethods).cancelBookedSlotAndFree(
            date: selectedDate,
            slotLabel: slot.label,
            onSuccess: () async {
              await _loadSelectedDay(selectedDate);
              await _loadSchedule();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${slot.label} is free again')),
              );
            },
            onFailed: (msg) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
          );
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => status = value);
    await ref.read(apimethods).updateAvailability(
          date: selectedDate,
          timeSlots: '',
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
    // Booked slots cannot be deleted — protect the patient's appointment.
    final booking = await ref.read(apimethods).getSlotBookingInfo(
          date: selectedDate,
          timeSlots: slot,
        );
    if (!mounted) return;

    if (booking.booked) {
      await _onBookedSlotTap(
        DoctorAvailabilitySlot(
          label: slot,
          open: false,
          booked: true,
          appointmentId: booking.appointmentId,
          bookedBy: booking.bookedBy,
        ),
      );
      return;
    }

    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: 'Delete slot?',
      message:
          'Remove $slot from ${DateFormat.yMMMMEEEEd().format(selectedDate)}? This only removes an open time — no patient is booked here.',
      confirmLabel: 'Delete',
      icon: EneftyIcons.trash_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(apimethods).removeTimeSlot(
            date: selectedDate,
            timeSlots: slot,
            onSuccess: (value) async {
              _applySelectedDayData(value);
              await _loadSchedule();
            },
          );
    } on SlotBookedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This slot was just booked. Refresh and try again.'),
        ),
      );
      await _loadSelectedDay(selectedDate);
      await _loadSchedule();
    }
  }

  Future<void> _showAddSlotSheet() async {
    final result = await showAddAvailabilitySlotSheet(
      context,
      date: selectedDate,
      initialDayOpen: status || availability.isNotEmpty,
    );
    if (result == null || !mounted) return;

    // Confirm when adding many slots onto a day that already has some.
    if (result.slotLabels.isNotEmpty && availability.isNotEmpty) {
      final overlaps = _overlappingExistingLabels(
        existing: availability,
        incoming: result.slotLabels,
      );
      final message = overlaps.isEmpty
          ? 'You already have ${availability.length} slot(s) on this day. '
              'New times will be added alongside them (existing slots stay).'
          : 'Some times already exist or may overlap open slots:\n'
              '${overlaps.take(5).join('\n')}'
              '${overlaps.length > 5 ? '\n…' : ''}\n\n'
              'Duplicates are skipped. New free times will be added.';

      final ok = await showYarisaConfirmationDialog(
        context,
        title: 'Add to this day?',
        message: message,
        confirmLabel: 'Add slots',
        cancelLabel: 'Cancel',
        icon: EneftyIcons.calendar_add_outline,
      );
      if (!ok || !mounted) return;
    }

    final write = await ref.read(apimethods).updateAvailabilitySlots(
          date: selectedDate,
          slotLabels: result.slotLabels,
          status: result.dayOpen || result.slotLabels.isNotEmpty,
          onSuccess: (value) async {
            _applySelectedDayData(value);
            await _loadSchedule();
          },
          onFailed: _showVerificationRequired,
        );

    if (!mounted) return;
    final parts = <String>[];
    if (write.added > 0) {
      parts.add(write.added == 1
          ? '1 new slot added'
          : '${write.added} new slots added');
    }
    if (write.skippedExisting > 0) {
      parts.add('${write.skippedExisting} already open');
    }
    if (write.skippedBooked > 0) {
      parts.add('${write.skippedBooked} booked (left unchanged)');
    }
    if (parts.isEmpty && result.slotLabels.isEmpty) {
      parts.add(result.dayOpen ? 'Day opened' : 'Day updated');
    }
    if (parts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parts.join(' · '))),
      );
    }
  }

  /// Labels that already exist or whose time ranges overlap an existing slot.
  List<String> _overlappingExistingLabels({
    required List<String> existing,
    required List<String> incoming,
  }) {
    final hits = <String>[];
    final existingRanges = existing
        .map(_parseSlotRange)
        .whereType<_MinuteRange>()
        .toList();
    for (final label in incoming) {
      if (existing.any((e) => e.trim() == label.trim())) {
        hits.add('$label (already exists)');
        continue;
      }
      final range = _parseSlotRange(label);
      if (range == null) continue;
      for (final other in existingRanges) {
        if (range.overlaps(other)) {
          hits.add('$label (overlaps an open slot)');
          break;
        }
      }
    }
    return hits;
  }

  _MinuteRange? _parseSlotRange(String label) {
    final parts = label.split(RegExp(r'\s*[-–—]\s*'));
    if (parts.length < 2) return null;
    final a = _parseTimeOfDay(parts[0].trim());
    final b = _parseTimeOfDay(parts.sublist(1).join(' - ').trim());
    if (a == null || b == null) return null;
    final start = a.hour * 60 + a.minute;
    final end = b.hour * 60 + b.minute;
    if (end <= start) return null;
    return _MinuteRange(start, end);
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final cleaned = raw.trim().toUpperCase();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    ).firstMatch(cleaned);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    final mer = match.group(3);
    if (mer == 'PM' && hour < 12) hour += 12;
    if (mer == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(apimethods).loading;
    final openDays = schedule.where((d) => d.hasOpenSlots).length;

    return DoctorScaffold(
      title: 'Availability',
      subtitle: openDays == 0
          ? 'Publish days patients can book'
          : '$openDays open day${openDays == 1 ? '' : 's'}',
      showBack: false,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotSheet,
        backgroundColor: DoctorUi.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        color: DoctorUi.primary,
        onRefresh: () async {
          await _loadSchedule();
          await _loadSelectedDay(selectedDate);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            DoctorCard(
              child: Row(
                children: [
                  Icon(EneftyIcons.info_circle_outline,
                      size: 18, color: DoctorUi.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap a day, open it for booking, then add time slots patients can choose.',
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AvailabilityViewToggle(
              mode: viewMode,
              onChanged: (mode) => setState(() => viewMode = mode),
            ),
            const SizedBox(height: 12),
            if (viewMode == AvailabilityViewMode.calendar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _legendDot(DoctorUi.primary, 'Selected'),
                    const SizedBox(width: 14),
                    _legendDot(Colors.green, 'Has slots'),
                    const SizedBox(width: 14),
                    _legendDot(DoctorUi.border, 'Empty'),
                  ],
                ),
              ),
            if (scheduleLoading)
              const ScheduleSkeleton()
            else if (viewMode == AvailabilityViewMode.calendar)
              AvailabilityCalendar(
                visibleMonth: visibleMonth,
                selectedDate: selectedDate,
                schedule: schedule,
                onMonthChanged: (month) =>
                    setState(() => visibleMonth = month),
                onDateSelected: _selectDate,
              )
            else
              AvailabilityListView(
                schedule: schedule,
                selectedDate: selectedDate,
                onDateSelected: _selectDate,
              ),
            const SizedBox(height: 16),
            DoctorSectionHeader(
              title: 'Selected day',
              count: daySlots.isEmpty ? null : daySlots.length,
            ),
            SelectedDaySlotsPanel(
              date: selectedDate,
              loading: loading,
              status: status,
              slots: daySlots,
              onStatusChanged: _toggleStatus,
              onRemoveOpenSlot: (s) => _removeSlot(s.label),
              onBookedSlotTap: _onBookedSlotTap,
              onAddSlot: _showAddSlotSheet,
            ),
          ],
        ),
      ),
    );
  }
}

class _MinuteRange {
  const _MinuteRange(this.start, this.end);
  final int start;
  final int end;
  bool overlaps(_MinuteRange other) => start < other.end && other.start < end;
}

Widget _legendDot(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DoctorUi.muted,
        ),
      ),
    ],
  );
}
