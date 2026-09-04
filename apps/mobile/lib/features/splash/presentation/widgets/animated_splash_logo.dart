import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Vector logo widget matching the scale and styling of the splash logo.
class AnimatedSplashLogo extends StatelessWidget {
  /// Optional parent animation driving scale and fade transitions.
  final Animation<double>? animation;

  /// Target display size for the logo.
  final double size;

  /// Creates an animated splash logo.
  const AnimatedSplashLogo({super.key, this.animation, this.size = 200.0});

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      'assets/svg/ic_splash_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final parentAnimation = animation;
    if (parentAnimation == null) {
      return image;
    }

    final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: parentAnimation, curve: Curves.easeOutCubic),
    );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: parentAnimation, curve: Curves.easeIn));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(opacity: fadeAnimation, child: image),
    );
  }
}
