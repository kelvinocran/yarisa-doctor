import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Result of the add-availability bottom sheet.
class AddSlotResult {
  const AddSlotResult({
    required this.slotLabels,
    required this.dayOpen,
  });

  /// One or many labels like `"6:00 AM - 6:30 AM"`.
  final List<String> slotLabels;
  final bool dayOpen;
}

/// Sheet: pick a window, optionally split into fixed-length bookable slots.
Future<AddSlotResult?> showAddAvailabilitySlotSheet(
  BuildContext context, {
  required DateTime date,
  required bool initialDayOpen,
}) {
  return showModalBottomSheet<AddSlotResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddAvailabilitySlotSheet(
      date: date,
      initialDayOpen: initialDayOpen,
    ),
  );
}

class _AddAvailabilitySlotSheet extends StatefulWidget {
  const _AddAvailabilitySlotSheet({
    required this.date,
    required this.initialDayOpen,
  });

  final DateTime date;
  final bool initialDayOpen;

  @override
  State<_AddAvailabilitySlotSheet> createState() =>
      _AddAvailabilitySlotSheetState();
}

class _AddAvailabilitySlotSheetState extends State<_AddAvailabilitySlotSheet> {
  TimeOfDay? _start;
  TimeOfDay? _end;
  late bool _dayOpen;
  bool _splitIntoSlots = true;
  int _slotMinutes = 30;
  String? _error;

  static const _intervals = <(String, int)>[
    ('30 min', 30),
    ('45 min', 45),
    ('1 hr', 60),
    ('1.5 hr', 90),
  ];

  @override
  void initState() {
    super.initState();
    _dayOpen = widget.initialDayOpen;
  }

  String _format(TimeOfDay? t) {
    if (t == null) return '';
    return t.format(context);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int total) {
    final normalized = total % (24 * 60);
    final safe = normalized < 0 ? normalized + 24 * 60 : normalized;
    return TimeOfDay(hour: safe ~/ 60, minute: safe % 60);
  }

  Future<void> _pickStart() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Start time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: DoctorUi.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (value == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _start = value;
      _error = null;
      if (_end != null && _toMinutes(_end!) <= _toMinutes(value)) {
        _end = null;
      }
    });
  }

  Future<void> _pickEnd() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _end ??
          (_start != null
              ? _fromMinutes(_toMinutes(_start!) + 60)
              : const TimeOfDay(hour: 17, minute: 0)),
      helpText: 'End time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: DoctorUi.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (value == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _end = value;
      _error = null;
    });
  }

  /// Build discrete slots from start→end using [_slotMinutes].
  List<String> _buildSlots() {
    if (_start == null || _end == null) return const [];
    final startM = _toMinutes(_start!);
    final endM = _toMinutes(_end!);
    if (endM <= startM) return const [];

    if (!_splitIntoSlots) {
      return ['${_format(_start)} - ${_format(_end)}'];
    }

    final labels = <String>[];
    var cursor = startM;
    while (cursor + _slotMinutes <= endM) {
      final a = _fromMinutes(cursor);
      final b = _fromMinutes(cursor + _slotMinutes);
      labels.add('${_format(a)} - ${_format(b)}');
      cursor += _slotMinutes;
    }
    return labels;
  }

  int get _windowMinutes {
    if (_start == null || _end == null) return 0;
    final d = _toMinutes(_end!) - _toMinutes(_start!);
    return d > 0 ? d : 0;
  }

  void _submit() {
    if (_start == null && _end == null) {
      if (!_dayOpen && !widget.initialDayOpen) {
        setState(() => _error = 'Open the day or add a time window');
        return;
      }
      Navigator.pop(
        context,
        AddSlotResult(slotLabels: const [], dayOpen: _dayOpen),
      );
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Choose both start and end times');
      return;
    }
    if (_toMinutes(_end!) <= _toMinutes(_start!)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }

    final slots = _buildSlots();
    if (slots.isEmpty) {
      setState(() {
        _error = _splitIntoSlots
            ? 'Window is shorter than $_slotMinutes min — widen the range or pick a smaller interval'
            : 'Could not create a slot';
      });
      return;
    }

    Navigator.pop(
      context,
      AddSlotResult(slotLabels: slots, dayOpen: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final dateLabel = DateFormat.yMMMMEEEEd().format(widget.date);
    final preview = _buildSlots();
    final canSave = _dayOpen != widget.initialDayOpen ||
        (_start != null && _end != null) ||
        _dayOpen;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: DoctorUi.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DoctorUi.primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              EneftyIcons.calendar_add_outline,
                              color: DoctorUi.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add availability',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateLabel,
                                  style: TextStyle(
                                    color: DoctorUi.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                color: DoctorUi.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DayOpenCard(
                        open: _dayOpen,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _dayOpen = v;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Working window',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: DoctorUi.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeCard(
                              label: 'Starts',
                              value: _start == null
                                  ? 'Pick time'
                                  : _format(_start),
                              filled: _start != null,
                              onTap: _pickStart,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: DoctorUi.muted,
                            ),
                          ),
                          Expanded(
                            child: _TimeCard(
                              label: 'Ends',
                              value:
                                  _end == null ? 'Pick time' : _format(_end),
                              filled: _end != null,
                              onTap: _pickEnd,
                            ),
                          ),
                        ],
                      ),
                      if (_windowMinutes > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          _windowLabel(_windowMinutes),
                          style: TextStyle(
                            color: DoctorUi.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Material(
                        color: DoctorUi.fieldBg,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Break into multiple slots',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _splitIntoSlots
                                          ? 'Patients book short sessions'
                                          : 'One continuous block only',
                                      style: TextStyle(
                                        color: DoctorUi.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _splitIntoSlots,
                                activeTrackColor:
                                    DoctorUi.primary.withValues(alpha: .45),
                                activeThumbColor: DoctorUi.primary,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _splitIntoSlots = v;
                                    _error = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_splitIntoSlots) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Slot length',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: DoctorUi.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _intervals.map((d) {
                            final selected = _slotMinutes == d.$2;
                            return ChoiceChip(
                              selected: selected,
                              label: Text(d.$1),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _slotMinutes = d.$2;
                                  _error = null;
                                });
                              },
                              selectedColor:
                                  DoctorUi.primary.withValues(alpha: .15),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: selected ? DoctorUi.primary : null,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? DoctorUi.primary.withValues(alpha: .4)
                                    : DoctorUi.border,
                              ),
                              backgroundColor: DoctorUi.fieldBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                      ],
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              _splitIntoSlots
                                  ? 'Preview · ${preview.length} slot${preview.length == 1 ? '' : 's'}'
                                  : 'Preview',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: DoctorUi.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DoctorUi.fieldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DoctorUi.border),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: preview
                                .take(24)
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DoctorUi.surface,
                                      borderRadius: BorderRadius.circular(50),
                                      border:
                                          Border.all(color: DoctorUi.border),
                                    ),
                                    child: Text(
                                      s,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (preview.length > 24)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '+${preview.length - 24} more not shown',
                              style: TextStyle(
                                color: DoctorUi.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canSave ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoctorUi.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        preview.isEmpty
                            ? (_dayOpen ? 'Open this day' : 'Save')
                            : preview.length == 1
                                ? 'Save 1 slot'
                                : 'Save ${preview.length} slots',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _windowLabel(int minutes) {
    if (minutes < 60) return '$minutes minute window';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hour${h == 1 ? '' : 's'} window';
    return '$h hr $m min window';
  }
}

class _DayOpenCard extends StatelessWidget {
  const _DayOpenCard({required this.open, required this.onChanged});

  final bool open;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: open ? Colors.green.withValues(alpha: .08) : DoctorUi.fieldBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!open),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: open
                      ? Colors.green.withValues(alpha: .15)
                      : DoctorUi.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  open
                      ? Icons.check_circle_rounded
                      : Icons.event_busy_outlined,
                  color: open ? Colors.green : DoctorUi.muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      open ? 'Day is open for booking' : 'Day is closed',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: open ? Colors.green.shade800 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      open
                          ? 'Patients can see this day'
                          : 'Turn on so patients can book',
                      style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: open,
                activeTrackColor: Colors.green.withValues(alpha: .45),
                activeThumbColor: Colors.green,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.value,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? DoctorUi.primary.withValues(alpha: .08)
          : DoctorUi.fieldBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled
                  ? DoctorUi.primary.withValues(alpha: .35)
                  : DoctorUi.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    EneftyIcons.clock_outline,
                    size: 14,
                    color: filled ? DoctorUi.primary : DoctorUi.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: filled ? DoctorUi.primary : DoctorUi.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: filled ? null : DoctorUi.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
