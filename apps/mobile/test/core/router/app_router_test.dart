import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App router route registration tests', () {
    test('contains route for /verification', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/verification'),
      );
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /verification/role-select', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/verification/role-select'),
      );
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /verification/upload', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/verification/upload'),
      );
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /verification/success', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/verification/success'),
      );
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /profile/content', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/profile/content'),
      );
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /search', () {
      final matches = appRouter.configuration.findMatch(Uri.parse('/search'));
      expect(matches.isNotEmpty, isTrue);
    });

    test('contains route for /community/post/:id', () {
      final matches = appRouter.configuration.findMatch(
        Uri.parse('/community/post/test-post-id'),
      );
      expect(matches.isNotEmpty, isTrue);
    });
  });
}
