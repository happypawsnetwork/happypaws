import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile/features/onboarding/presentation/widgets/animated_page_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen widget tests', () {
    testWidgets('renders first onboarding slide and action elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      // Verify title and subtitle for the initial slide
      expect(find.text('Welcome to Happy Paws'), findsOneWidget);
      expect(
        find.text(
          "Join Sri Lanka's trusted animal rescue community. We are here to help you find your new best friend or support a pet in need.",
        ),
        findsOneWidget,
      );

      // Verify indicator dots and interactive buttons exist
      expect(find.byType(AnimatedPageIndicator), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      expect(find.textContaining('Sign in'), findsOneWidget);
    });

    testWidgets('swipes manually to the second and third slides', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(autoSlideDuration: Duration(seconds: 100)),
        ),
      );

      expect(find.text('Welcome to Happy Paws'), findsOneWidget);

      // Drag left to transition to slide 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('A safe space for every paw'), findsOneWidget);
      expect(
        find.text(
          'Connect with verified shelters, rescuers, and adopters. We make sure every animal goes to a secure and loving home.',
        ),
        findsOneWidget,
      );

      // Drag left to transition to slide 3
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Find your way to a new friend'), findsOneWidget);
      expect(
        find.text(
          'Check the map to see adoptable pets in your city. Your new best friend might be just around the corner.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'advances automatically and loops from slide 3 back to slide 1',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: OnboardingScreen(autoSlideDuration: Duration(seconds: 2)),
          ),
        );

        expect(find.text('Welcome to Happy Paws'), findsOneWidget);

        // Advance timer by 2 seconds to reach slide 2
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('A safe space for every paw'), findsOneWidget);

        // Advance timer by another 2 seconds to reach slide 3
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Find your way to a new friend'), findsOneWidget);

        // Advance timer by another 2 seconds to loop back to slide 1
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Welcome to Happy Paws'), findsOneWidget);
      },
    );

    testWidgets('disposes timer and controller cleanly when unmounted', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Unmount the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      expect(find.byType(OnboardingScreen), findsNothing);

      // Advancing time should not trigger unhandled timers or memory errors
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
