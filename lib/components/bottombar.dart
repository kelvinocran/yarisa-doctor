import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  final List<BottomBarItem> items;
  final TextStyle? selectedTextStyle, unselectedTextStyle;
  final Color? selectedItemColor, unselectedItemColor, backgroundColor;
  final int? index;
  final bool showTitle, showDot;
  final bool showAllTitles;
  final Duration duration;
  final Curve curve;
  final double curveRadius, elevation;
  final Function(int)? onTap;

  const BottomBar({
    super.key,
    required this.items,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.index,
    this.curveRadius = 20,
    this.elevation = 20,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.showTitle = false,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuint,
    this.showAllTitles = false,
    this.showDot = false,
    this.onTap,
    this.backgroundColor,
  }) : assert(index != null);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showLabels = widget.showTitle || widget.showAllTitles;

    return Material(
      surfaceTintColor: widget.backgroundColor ??
          theme.bottomNavigationBarTheme.backgroundColor,
      color: widget.backgroundColor ??
          theme.bottomNavigationBarTheme.backgroundColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(widget.curveRadius),
        topRight: Radius.circular(widget.curveRadius),
      ),
      clipBehavior: Clip.none,
      elevation: widget.elevation,
      animationDuration: widget.duration,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: showLabels ? 6 : 4,
          ),
          child: Row(
            children: [
              for (var i = 0; i < widget.items.length; i++)
                Expanded(
                  child: _BottomBarTab(
                    item: widget.items[i],
                    selected: i == widget.index,
                    showLabel: showLabels,
                    selectedColor: widget.items[i].selectedColor ??
                        widget.selectedItemColor ??
                        theme.bottomNavigationBarTheme.selectedItemColor ??
                        theme.colorScheme.primary,
                    unselectedColor: widget.items[i].unselectedColor ??
                        widget.unselectedItemColor ??
                        Colors.grey,
                    duration: widget.duration,
                    curve: widget.curve,
                    onTap: () {
                      widget.onTap?.call(i);
                      controller.forward(from: 0);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.selectedColor,
    required this.unselectedColor,
    required this.duration,
    required this.curve,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final bool showLabel;
  final Color selectedColor;
  final Color unselectedColor;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1.0 : 0.0),
      curve: curve,
      duration: duration,
      builder: (context, t, _) {
        final color = Color.lerp(unselectedColor, selectedColor, t)!;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: color, size: 24),
                    child: selected
                        ? (item.activeIcon ?? item.icon)
                        : item.icon,
                  ),
                  if (showLabel) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: color,
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                      child: item.title,
                    ),
                  ] else if (selected) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BottomBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final Widget title;
  final Color? selectedColor;
  final Color? unselectedColor;

  const BottomBarItem({
    Key? key,
    required this.icon,
    required this.title,
    this.activeIcon,
    this.selectedColor,
    this.unselectedColor,
  });
}
