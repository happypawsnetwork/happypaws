import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Renders smoothly animated dots synchronized with [PageController] scroll position.
class AnimatedPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedPageIndicator({
    super.key,
    required this.controller,
    required this.count,
    this.activeColor = AppColors.primary,
    this.inactiveColor = const Color(0xFFCBD5E1),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentPage = (controller.hasClients && controller.page != null)
            ? controller.page!
            : (controller.initialPage.toDouble());

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final difference = (currentPage - index).abs().clamp(0.0, 1.0);
            final progress = 1.0 - difference;

            final color =
                Color.lerp(inactiveColor, activeColor, progress) ??
                inactiveColor;
            final size = lerpDouble(7.0, 8.5, progress) ?? 7.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          }),
        );
      },
    );
  }
}
