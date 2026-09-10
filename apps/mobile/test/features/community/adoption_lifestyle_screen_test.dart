import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/community/presentation/controllers/create_post_controller.dart';
import 'package:mobile/features/community/presentation/screens/create/adoption/adoption_lifestyle_screen.dart';
import 'package:provider/provider.dart';

class _FakePostRepository implements IPostRepository {
  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async {
    return (urgencyLevel: 'Medium', reason: null);
  }

  @override
  Future<Post> createPost(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePost(String id) async {}

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Post>> getMapBoundsFeed({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    String? type,
  }) async => [];

  @override
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async => [];

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<Post?> getPostById(String id) async => null;

  @override
  Future<List<Post>> searchPosts({
    String? query,
    String? species,
    String? location,
    String? urgency,
    String? type,
    double? lat,
    double? lon,
    double? radiusKm,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
    int pageSize = 20,
  }) async => [];

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async {
    return (isLiked: true, likeCount: 1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePostRepository postRepository;
  late CreatePostController controller;

  setUp(() {
    postRepository = _FakePostRepository();
    controller = CreatePostController(postRepository);
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/community/create/adoption/lifestyle',
      routes: [
        GoRoute(
          path: '/community/create/adoption/lifestyle',
          builder: (context, state) => const AdoptionLifestyleScreen(),
        ),
        GoRoute(
          path: '/community/create/adoption/photos',
          builder: (context, state) =>
              const Scaffold(body: Text('Adoption Photos Screen')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CreatePostController>.value(value: controller),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renders all lifestyle sections and cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.text('What kind of home does this animal need?'),
      findsOneWidget,
    );
    expect(find.text('Minimum home size required'), findsOneWidget);
    expect(find.text('Apartment / Flat'), findsOneWidget);
    expect(find.text('Single house'), findsOneWidget);
    expect(find.text('Estate / Acreage'), findsOneWidget);
    expect(find.text('Outdoor environment'), findsOneWidget);
    expect(find.text('Requires enclosed yard / garden'), findsOneWidget);
    expect(find.text('Good with children'), findsNWidgets(2));
    expect(find.text('Required activity tempo'), findsOneWidget);
    expect(find.text('Relaxed & calm'), findsOneWidget);
    expect(find.text('Moderately active'), findsOneWidget);
    expect(find.text('High energy'), findsOneWidget);
    expect(find.text('Good with pets'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('allows selecting minimum home size radio cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(controller.lifestyleHomeSize, isNull);

    // Tap Apartment
    await tester.tap(find.text('Apartment / Flat'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleHomeSize, 'Apartment');

    // Tap Single house
    await tester.tap(find.text('Single house'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleHomeSize, 'SingleHouse');

    // Tap Estate
    await tester.tap(find.text('Estate / Acreage'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleHomeSize, 'Estate');
  });

  testWidgets('allows toggling enclosed yard and good with children cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(controller.lifestyleRequiresEnclosedYard, isFalse);
    expect(controller.lifestyleGoodWithChildren, isTrue);

    // Scroll and tap the enclosed yard toggle card
    await tester.ensureVisible(find.text('Requires enclosed yard / garden'));
    await tester.tap(find.text('Requires enclosed yard / garden'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleRequiresEnclosedYard, isTrue);

    // Scroll and tap the good with children toggle card subtitle
    await tester.ensureVisible(
      find.text('Comfortable around children under 12 years old.'),
    );
    await tester.tap(
      find.text('Comfortable around children under 12 years old.'),
    );
    await tester.pumpAndSettle();
    expect(controller.lifestyleGoodWithChildren, isFalse);
  });

  testWidgets('allows selecting activity tempo and navigates on continue', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(controller.lifestyleActivityTempo, isNull);

    await tester.ensureVisible(find.text('Relaxed & calm'));
    await tester.tap(find.text('Relaxed & calm'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleActivityTempo, 'RelaxedAndCalm');

    await tester.ensureVisible(find.text('Moderately active'));
    await tester.tap(find.text('Moderately active'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleActivityTempo, 'ModeratelyActive');

    await tester.ensureVisible(find.text('High energy'));
    await tester.tap(find.text('High energy'));
    await tester.pumpAndSettle();
    expect(controller.lifestyleActivityTempo, 'HighEnergy');

    // Tap Continue
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Adoption Photos Screen'), findsOneWidget);
  });

  testWidgets('allows adding and removing pet compatibility tags', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(controller.lifestyleGoodWithPets, isEmpty);

    // Tap Add animal
    await tester.ensureVisible(find.text('Add animal'));
    await tester.tap(find.text('Add animal'));
    await tester.pumpAndSettle();

    // Tap Dog in bottom sheet
    expect(find.text('Dog'), findsOneWidget);
    await tester.tap(find.text('Dog'));
    await tester.pumpAndSettle();

    expect(controller.lifestyleGoodWithPets, contains('Dog'));
    expect(find.text('Dog'), findsOneWidget);

    // Remove Dog chip
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(controller.lifestyleGoodWithPets, isEmpty);
  });
}
