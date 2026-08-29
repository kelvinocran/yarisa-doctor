import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/skeleton_loader.dart';

enum AvailabilityViewMode { calendar, list }

class AvailabilityViewToggle extends StatelessWidget {
  const AvailabilityViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final AvailabilityViewMode mode;
  final ValueChanged<AvailabilityViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DoctorUi.fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Calendar',
              icon: EneftyIcons.calendar_2_outline,
              selected: mode == AvailabilityViewMode.calendar,
              onTap: () => onChanged(AvailabilityViewMode.calendar),
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'List',
              icon: Icons.view_agenda_outlined,
              selected: mode == AvailabilityViewMode.list,
              onTap: () => onChanged(AvailabilityViewMode.list),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DoctorUi.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? DoctorUi.primary : DoctorUi.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected ? DoctorUi.primary : DoctorUi.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvailabilityCalendar extends StatelessWidget {
  const AvailabilityCalendar({
    super.key,
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
    final days = availabilityCalendarCells(visibleMonth);
    final byKey = {for (final d in schedule) d.dateKey: d};

    return DoctorCard(
      child: Column(
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
                child: Text(
                  DateFormat.yMMMM().format(visibleMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
          const SizedBox(height: 4),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
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
              final day = byKey[availabilityScheduleKey(date)];
              final selected = availabilityIsSameDay(date, selectedDate);
              final hasSlots = day?.hasOpenSlots == true;
              return Material(
                color: selected ? DoctorUi.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onDateSelected(date),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? DoctorUi.primary
                            : hasSlots
                                ? Colors.green.withValues(alpha: .65)
                                : DoctorUi.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.d().format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 6,
                          width: hasSlots ? 18 : 6,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : hasSlots
                                    ? Colors.green
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AvailabilityListView extends StatelessWidget {
  const AvailabilityListView({
    super.key,
    required this.schedule,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<AvailabilityDaySummary> schedule;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final openDays = schedule.where((d) => d.hasOpenSlots).toList();
    if (openDays.isEmpty) {
      return DoctorCard(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, color: DoctorUi.muted, size: 32),
            const SizedBox(height: 10),
            Text(
              'No open days yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: DoctorUi.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a day on the calendar and add time slots.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DoctorUi.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: openDays.map((day) {
        final selected = availabilityIsSameDay(day.date, selectedDate);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DoctorCard(
            onTap: () => onDateSelected(day.date),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat.yMMMMEEEEd().format(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${day.slots.length} slot${day.slots.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: selected ? DoctorUi.primary : DoctorUi.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final slot in day.slots.take(6))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? DoctorUi.primary.withValues(alpha: .12)
                              : DoctorUi.fieldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? DoctorUi.primary.withValues(alpha: .25)
                                : DoctorUi.border,
                          ),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: selected ? DoctorUi.primary : null,
                          ),
                        ),
                      ),
                    if (day.slots.length > 6)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DoctorUi.fieldBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${day.slots.length - 6} more',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: DoctorUi.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SelectedDaySlotsPanel extends StatefulWidget {
  const SelectedDaySlotsPanel({
    super.key,
    required this.date,
    required this.loading,
    required this.status,
    required this.slots,
    required this.onStatusChanged,
    required this.onRemoveOpenSlot,
    required this.onBookedSlotTap,
    required this.onAddSlot,
  });

  final DateTime date;
  final bool loading;
  final bool status;
  final List<DoctorAvailabilitySlot> slots;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<DoctorAvailabilitySlot> onRemoveOpenSlot;
  final ValueChanged<DoctorAvailabilitySlot> onBookedSlotTap;
  final VoidCallback onAddSlot;

  /// How many slots to show per page.
  static const int pageSize = 6;

  @override
  State<SelectedDaySlotsPanel> createState() => _SelectedDaySlotsPanelState();
}

class _SelectedDaySlotsPanelState extends State<SelectedDaySlotsPanel> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant SelectedDaySlotsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.date, widget.date) ||
        oldWidget.slots.length != widget.slots.length) {
      final maxPage = _maxPage(widget.slots.length);
      if (_page > maxPage) _page = maxPage;
      if (!_isSameDay(oldWidget.date, widget.date)) _page = 0;
    }
  }

  int _maxPage(int count) {
    if (count <= 0) return 0;
    return ((count - 1) / SelectedDaySlotsPanel.pageSize).floor();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DoctorAvailabilitySlot> get _pageSlots {
    final start = _page * SelectedDaySlotsPanel.pageSize;
    if (start >= widget.slots.length) return const [];
    final end =
        (start + SelectedDaySlotsPanel.pageSize).clamp(0, widget.slots.length);
    return widget.slots.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.slots.length;
    final openCount = widget.slots.where((s) => s.open).length;
    final bookedCount = widget.slots.where((s) => s.booked).length;
    final pageCount = total == 0 ? 0 : _maxPage(total) + 1;
    final pageSlots = _pageSlots;

    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMEEEEd().format(widget.date),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.status
                          ? 'Open · $openCount free · $bookedCount booked'
                          : 'Closed · $bookedCount booked still listed',
                      style: TextStyle(
                        color: widget.status
                            ? Colors.green.shade700
                            : DoctorUi.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: widget.status,
                activeTrackColor: DoctorUi.primary.withValues(alpha: .45),
                activeThumbColor: DoctorUi.primary,
                onChanged: widget.onStatusChanged,
              ),
            ],
          ),
          if (bookedCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Grey “Booked” slots cannot be deleted. Tap one to view the appointment or free the time.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (widget.loading)
            const SkeletonBox(
              height: 120,
              width: double.infinity,
              radius: 16,
            )
          else if (total == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: DoctorUi.fieldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(EneftyIcons.clock_outline,
                      size: 28, color: DoctorUi.muted),
                  const SizedBox(height: 10),
                  Text(
                    'No slots on this day',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: DoctorUi.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a window and split it into bookable times',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DoctorUi.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: widget.onAddSlot,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add slots'),
                  ),
                ],
              ),
            )
          else ...[
            if (pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      'Showing ${_page * SelectedDaySlotsPanel.pageSize + 1}–${_page * SelectedDaySlotsPanel.pageSize + pageSlots.length} of $total',
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Page ${_page + 1}/$pageCount',
                      style: TextStyle(
                        color: DoctorUi.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            GridView.builder(
              itemCount: pageSlots.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.15,
              ),
              itemBuilder: (context, index) {
                final slot = pageSlots[index];
                final parts = _splitSlotLabel(slot.label);
                return _SlotTile(
                  start: parts.$1,
                  end: parts.$2,
                  fullLabel: slot.label,
                  booked: slot.booked,
                  onDelete: slot.booked
                      ? null
                      : () => widget.onRemoveOpenSlot(slot),
                  onTap: slot.booked
                      ? () => widget.onBookedSlotTap(slot)
                      : null,
                );
              },
            ),
            if (pageCount > 1) ...[
              const SizedBox(height: 12),
              _SlotPaginationBar(
                page: _page,
                pageCount: pageCount,
                onPrev: _page > 0 ? () => setState(() => _page -= 1) : null,
                onNext: _page < pageCount - 1
                    ? () => setState(() => _page += 1)
                    : null,
                onPage: (p) => setState(() => _page = p),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAddSlot,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add more slots'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DoctorUi.primary,
                  side: BorderSide(
                    color: DoctorUi.primary.withValues(alpha: .35),
                  ),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Parse `"9:00 AM - 9:30 AM"` → (start, end); otherwise (label, null).
(String, String?) _splitSlotLabel(String label) {
  final parts = label.split(RegExp(r'\s*[-–—]\s*'));
  if (parts.length >= 2) {
    return (parts.first.trim(), parts.sublist(1).join(' - ').trim());
  }
  return (label.trim(), null);
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.start,
    required this.end,
    required this.fullLabel,
    required this.booked,
    required this.onDelete,
    required this.onTap,
  });

  final String start;
  final String? end;
  final String fullLabel;
  final bool booked;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = booked
        ? Colors.grey.withValues(alpha: .12)
        : DoctorUi.fieldBg;
    final accent = booked ? Colors.grey.shade600 : DoctorUi.primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: booked
                  ? Colors.grey.withValues(alpha: .35)
                  : DoctorUi.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  booked
                      ? Icons.lock_outline_rounded
                      : EneftyIcons.clock_outline,
                  size: 15,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booked)
                      Text(
                        'Booked',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: booked ? Colors.grey.shade800 : null,
                      ),
                    ),
                    if (end != null)
                      Text(
                        'to $end',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DoctorUi.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Remove $fullLabel',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDelete,
                  icon: Icon(
                    EneftyIcons.trash_outline,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotPaginationBar extends StatelessWidget {
  const _SlotPaginationBar({
    required this.page,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    // Show a compact window of page dots when many pages.
    const window = 5;
    var start = (page - window ~/ 2).clamp(0, (pageCount - window).clamp(0, pageCount));
    var end = (start + window).clamp(0, pageCount);
    if (end - start < window && pageCount >= window) {
      start = (end - window).clamp(0, pageCount);
    }

    return Row(
      children: [
        _PageIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrev,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = start; i < end; i++)
                GestureDetector(
                  onTap: () => onPage(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == page
                          ? DoctorUi.primary
                          : DoctorUi.primary.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _PageIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? DoctorUi.primary.withValues(alpha: .1)
          : DoctorUi.fieldBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: enabled ? DoctorUi.primary : DoctorUi.muted,
          ),
        ),
      ),
    );
  }
}

List<DateTime?> availabilityCalendarCells(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final leading = firstDay.weekday - 1;
  final total = DateUtils.getDaysInMonth(month.year, month.month);
  return [
    ...List<DateTime?>.filled(leading, null),
    ...List.generate(total, (i) => DateTime(month.year, month.month, i + 1)),
  ];
}

bool availabilityIsSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String availabilityScheduleKey(DateTime value) {
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '${value.year}-$m-$d';
}

DateTime availabilityDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
