import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height,
    this.width,
    this.radius = 12,
    this.margin,
  });

  final double? height;
  final double? width;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .08)
        : Colors.black.withValues(alpha: .06);
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .16)
        : Colors.black.withValues(alpha: .11);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .35, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      onEnd: () {},
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [baseColor, highlightColor, baseColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.margin,
  });

  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      radius: height,
      margin: margin,
    );
  }
}

class AppointmentSkeletonList extends StatelessWidget {
  const AppointmentSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const SkeletonBox(
        height: 128,
        width: double.infinity,
        radius: 20,
      ),
    );
  }
}

class ScheduleSkeleton extends StatelessWidget {
  const ScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 180, height: 16),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => const SkeletonBox(radius: 12),
        ),
      ],
    );
  }
}
