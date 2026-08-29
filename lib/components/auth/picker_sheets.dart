import 'package:country_picker/country_picker.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Shared presentation for doctor searchable pickers.
Future<T?> showDoctorPickerSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  // Unfocus any parent fields first so iOS keyboard doesn't fight the sheet.
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .45),
    builder: (ctx) {
      final height = MediaQuery.sizeOf(ctx).height;
      final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height * 0.78,
            width: double.infinity,
            decoration: BoxDecoration(
              color: DoctorUi.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

class _PickerChrome extends StatelessWidget {
  const _PickerChrome({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.searchHint,
    required this.searchController,
    required this.onQueryChanged,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = DoctorUi.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: DoctorUi.border,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: DoctorUi.primary.withValues(alpha: isDark ? .22 : .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: DoctorUi.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF1A1024),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: DoctorUi.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: DoctorUi.muted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: searchController,
            // Avoid autofocus: iOS keyboard + bottom sheet triggers
            // TUIKeyplane Auto Layout warnings/crashes.
            autofocus: false,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: TextStyle(
                color: DoctorUi.muted,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                EneftyIcons.search_normal_2_outline,
                color: DoctorUi.muted,
                size: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (_, value, __) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      searchController.clear();
                      onQueryChanged('');
                    },
                    icon: Icon(Icons.cancel_rounded,
                        size: 18, color: DoctorUi.muted),
                  );
                },
              ),
              filled: true,
              fillColor: DoctorUi.fieldBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: DoctorUi.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: DoctorUi.primary, width: 1.4),
              ),
            ),
            onChanged: onQueryChanged,
          ),
        ),
        Divider(height: 1, color: DoctorUi.border),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyPickerState extends StatelessWidget {
  const _EmptyPickerState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: DoctorUi.muted.withValues(alpha: .7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DoctorUi.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Country picker that matches doctor auth chrome (replaces package UI).
class DoctorCountryPickerSheet extends StatefulWidget {
  const DoctorCountryPickerSheet({
    super.key,
    this.selectedCountryCode,
  });

  final String? selectedCountryCode;

  static Future<Country?> show(
    BuildContext context, {
    String? selectedCountryCode,
  }) {
    return showDoctorPickerSheet<Country>(
      context: context,
      builder: (_) => DoctorCountryPickerSheet(
        selectedCountryCode: selectedCountryCode,
      ),
    );
  }

  @override
  State<DoctorCountryPickerSheet> createState() =>
      _DoctorCountryPickerSheetState();
}

class _DoctorCountryPickerSheetState extends State<DoctorCountryPickerSheet> {
  final _search = TextEditingController();
  late final List<Country> _all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _all = CountryService().getAll()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Country> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase().contains(q) ||
          c.phoneCode.contains(q) ||
          c.displayNameNoCountryCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return _PickerChrome(
      title: 'Select country',
      subtitle: 'Search by name, code, or dial code',
      icon: Icons.public_rounded,
      searchHint: 'Search countries…',
      searchController: _search,
      onQueryChanged: (v) => setState(() => _query = v),
      child: items.isEmpty
          ? const _EmptyPickerState(message: 'No country matches your search')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final country = items[index];
                final selected =
                    country.countryCode == widget.selectedCountryCode;
                return _PickerTile(
                  leading: Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: country.name,
                  subtitle: '+${country.phoneCode} · ${country.countryCode}',
                  selected: selected,
                  onTap: () => Navigator.pop(context, country),
                );
              },
            ),
    );
  }
}

/// Specialty picker sheet (redesigned).
class DoctorSpecialtyPickerSheet extends StatefulWidget {
  const DoctorSpecialtyPickerSheet({
    super.key,
    required this.options,
    required this.selected,
  });

  final List<String> options;
  final String? selected;

  static Future<String?> show(
    BuildContext context, {
    required List<String> options,
    String? selected,
  }) {
    return showDoctorPickerSheet<String>(
      context: context,
      builder: (_) => DoctorSpecialtyPickerSheet(
        options: options,
        selected: selected,
      ),
    );
  }

  @override
  State<DoctorSpecialtyPickerSheet> createState() =>
      _DoctorSpecialtyPickerSheetState();
}

class _DoctorSpecialtyPickerSheetState
    extends State<DoctorSpecialtyPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return _PickerChrome(
      title: 'Select specialty',
      subtitle: '${widget.options.length} specialties available',
      icon: Icons.medical_services_outlined,
      searchHint: 'Search specialties…',
      searchController: _search,
      onQueryChanged: (v) => setState(() => _query = v),
      child: items.isEmpty
          ? const _EmptyPickerState(
              message: 'No specialty matches your search',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final option = items[index];
                final selected = option == widget.selected;
                return _PickerTile(
                  leading: Icon(
                    Icons.local_hospital_outlined,
                    size: 20,
                    color: selected ? DoctorUi.primary : DoctorUi.muted,
                  ),
                  title: option,
                  selected: selected,
                  onTap: () => Navigator.pop(context, option),
                );
              },
            ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = DoctorUi.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? DoctorUi.primary.withValues(alpha: isDark ? .2 : .1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? DoctorUi.primary.withValues(alpha: .45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 36, child: Center(child: leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: DoctorUi.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: DoctorUi.primary)
              else
                Icon(
                  Icons.circle_outlined,
                  size: 20,
                  color: DoctorUi.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
