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
  late Animation animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 200), //controll animation duration
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    animation = ColorTween(
      begin: Colors.grey,
      end: Colors.red,
    ).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      surfaceTintColor: widget.backgroundColor ??
          theme.bottomNavigationBarTheme.backgroundColor,
      color: widget.backgroundColor ??
          theme.bottomNavigationBarTheme.backgroundColor,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.curveRadius),
          topRight: Radius.circular(widget.curveRadius)),
      clipBehavior: Clip.none,
      elevation: widget.elevation,
      animationDuration: widget.duration,
      child: SafeArea(
          child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal:
                (!widget.showTitle || !widget.showAllTitles) ? 15.0 : 20.0,
            vertical:
                (!widget.showTitle || !widget.showAllTitles) ? 5.0 : 10.0),
        child: Row(
          mainAxisAlignment: widget.items.length <= 2
              ? MainAxisAlignment.spaceEvenly
              : MainAxisAlignment.spaceBetween,
          children: [
            ...widget.items.map((item) {
              final selectedColor = item.selectedColor ??
                  widget.selectedItemColor ??
                  theme.bottomNavigationBarTheme.selectedItemColor!;

              final unselectedColor = item.unselectedColor ??
                  widget.unselectedItemColor ??
                  Colors.grey;

              return TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: widget.items.indexOf(item) == widget.index ? 1.0 : 0.0,
                  ),
                  curve: widget.curve,
                  duration: widget.duration,
                  builder: (context, t, _) {
                    return InkWell(
                      onTap: () {
                        widget.onTap?.call(widget.items.indexOf(item));
                        controller.forward();
                      },
                      focusColor: selectedColor.withOpacity(0.1),
                      highlightColor: selectedColor.withOpacity(0.1),
                      splashColor: selectedColor.withOpacity(0.1),
                      hoverColor: selectedColor.withOpacity(0.1),
                      customBorder: const StadiumBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconTheme(
                                data: IconThemeData(
                                  color: Color.lerp(
                                      unselectedColor, selectedColor, t),
                                  size: 25,
                                ),
                                child:
                                    widget.items.indexOf(item) == widget.index
                                        ? item.activeIcon ?? item.icon
                                        : item.icon),
                            Visibility(
                              visible: widget.showTitle || widget.showAllTitles,
                              child: Column(
                                children: [
                                  const SizedBox(height: 5),
                                  DefaultTextStyle(
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Color.lerp(
                                              widget.showAllTitles
                                                  ? Colors.grey
                                                  : selectedColor
                                                      .withOpacity(0.0),
                                              selectedColor,
                                              t),
                                        ),
                                    child: item.title,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            })
          ],
        ),
      )),
    );
  }
}

class VerticalBar extends StatelessWidget {
  final List<BottomBarItem> items;
  final TextStyle? selectedTextStyle, unselectedTextStyle;
  final Color? selectedItemColor, unselectedItemColor, backgroundColor;
  final int? index;
  final bool showTitle, showDot, safeArea;
  final bool showAllTitles;
  final Duration duration;
  final Curve curve;
  final double curveRadius, elevation, width;
  final Function(int)? onTap;

  const VerticalBar({
    super.key,
    required this.items,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.index,
    this.curveRadius = 20,
    this.elevation = 20,
    this.width = 100,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.showTitle = false,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuint,
    this.showAllTitles = false,
    this.showDot = false,
    this.safeArea = false,
    this.onTap,
    this.backgroundColor,
  })  : assert(index != null),
        assert(width >= 100);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      surfaceTintColor:
          backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      color: backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(curveRadius),
          topRight: Radius.circular(curveRadius)),
      clipBehavior: Clip.none,
      elevation: elevation,
      animationDuration: duration,
      child: SafeArea(
        left: safeArea,
        right: safeArea,
        child: Container(
          width: showTitle || showAllTitles ? width * 2 : width,
          padding: EdgeInsets.symmetric(
              horizontal: (!showTitle || !showAllTitles) ? 20.0 : 20.0,
              vertical: (!showTitle || !showAllTitles) ? 10.0 : 10.0),
          child: Column(
            mainAxisAlignment: items.length <= 2
                ? MainAxisAlignment.spaceEvenly
                : MainAxisAlignment.spaceBetween,
            children: [
              ...items.map((item) {
                final selectedColor =
                    item.selectedColor ?? selectedItemColor ?? Colors.grey;

                final unselectedColor = item.unselectedColor ??
                    unselectedItemColor ??
                    theme.iconTheme.color;

                return TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: items.indexOf(item) == index ? 1.0 : 0.0,
                    ),
                    curve: curve,
                    duration: duration,
                    builder: (context, t, _) {
                      return InkWell(
                        onTap: () => onTap?.call(items.indexOf(item)),
                        focusColor: selectedColor.withOpacity(0.1),
                        highlightColor: selectedColor.withOpacity(0.1),
                        splashColor: selectedColor.withOpacity(0.1),
                        hoverColor: selectedColor.withOpacity(0.1),
                        customBorder: const StadiumBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconTheme(
                                    data: IconThemeData(
                                      color: Color.lerp(
                                          unselectedColor, selectedColor, t),
                                      size: 24,
                                    ),
                                    child: items.indexOf(item) == index
                                        ? item.activeIcon ?? item.icon
                                        : item.icon,
                                  ),
                                  Flexible(
                                    child: Visibility(
                                      visible: showTitle || showAllTitles,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 0),
                                          Expanded(
                                            child: DefaultTextStyle(
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    color: Color.lerp(
                                                        showAllTitles
                                                            ? Colors.grey
                                                            : selectedColor
                                                                .withOpacity(
                                                                    0.0),
                                                        selectedColor,
                                                        t),
                                                  ),
                                              child: item.title,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                  visible: showDot,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 5),
                                      CircleAvatar(
                                        radius: 2,
                                        backgroundColor: Color.lerp(
                                            showAllTitles
                                                ? Colors.grey
                                                : selectedColor
                                                    .withOpacity(0.0),
                                            selectedColor,
                                            t),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      );
                    });
              })
            ],
          ),
        ),
      ),
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
