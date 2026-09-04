import 'package:flutter/foundation.dart';

/// Immutable model representing a single onboarding slide.
@immutable
class OnboardingItem {
  /// Local asset path to the illustration displayed at the top of the slide.
  final String imagePath;

  /// Main headline text displayed in bold below the illustration.
  final String title;

  /// Supporting description text explaining the feature or mission.
  final String subtitle;

  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  /// Default slide configuration used across the welcome onboarding carousel.
  static const List<OnboardingItem> defaultItems = [
    OnboardingItem(
      imagePath: 'assets/images/illus_onboarding_welcome.png',
      title: 'Welcome to Happy Paws',
      subtitle: "Join Sri Lanka's trusted animal rescue community. We are here to help you find your new best friend or support a pet in need.",
    ),
    OnboardingItem(
      imagePath: 'assets/images/illus_onboarding_trust.png',
      title: 'A safe space for every paw',
      subtitle: 'Connect with verified shelters, rescuers, and adopters. We make sure every animal goes to a secure and loving home.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/illus_onboarding_action.png',
      title: 'Find your way to a new friend',
      subtitle: 'Check the map to see adoptable pets in your city. Your new best friend might be just around the corner.',
    ),
  ];
}
