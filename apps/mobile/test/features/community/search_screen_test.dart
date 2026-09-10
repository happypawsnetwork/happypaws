import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/presentation/controllers/search_feed_controller.dart';
import 'package:mobile/features/community/presentation/screens/search_screen.dart';

import 'search_feed_controller_test.dart';

Widget _buildTestableWidget({required SearchFeedController controller}) {
  return MaterialApp(
    home: ChangeNotifierProvider<SearchFeedController>.value(
      value: controller,
      child: const SearchScreen(),
    ),
  );
}

Post _makeTestPost({
  required String id,
  required String title,
  String species = 'Dog',
  String urgency = 'High',
  String location = 'Maplewood Park',
  bool isRecommended = false,
}) {
  return Post(
    id: id,
    type: PostType.adoptionListing,
    status: PostStatus.active,
    title: title,
    body: 'Looking for a home for $title',
    likeCount: 5,
    isLikedByCurrentUser: false,
    authorId: 10,
    authorDisplayName: 'Foster Sarah',
    locationLabel: location,
    animalSpecies: species,
    animalName: 'Sunny',
    photoCount: 0,
    media: const [],
    createdAt: DateTime(2026, 9, 1),
    urgencyLevel: urgency,
    isRecommended: isRecommended,
  );
}

void main() {
  late MockSearchPostRepository mockRepo;
  late SearchFeedController controller;

  setUp(() {
    mockRepo = MockSearchPostRepository();
    controller = SearchFeedController(mockRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('renders search input field, filter icon, and quick chips', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search animals, breeds, places...'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('🐕 Dogs'), findsOneWidget);
    expect(find.text('🐈 Cats'), findsOneWidget);
    expect(find.text('🏠 Find Home'), findsOneWidget);
    expect(find.text('🚨 Rescue'), findsOneWidget);
  });

  testWidgets('typing in search bar triggers query change', (tester) async {
    mockRepo.cannedPosts = [_makeTestPost(id: '1', title: 'Adopt Sunny')];

    await tester.pumpWidget(_buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Sunny');
    // Wait for debounce
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(controller.query, 'Sunny');
    expect(find.text('Adopt Sunny'), findsOneWidget);
  });

  testWidgets('tapping quick filter chip applies filter and updates UI', (
    tester,
  ) async {
    mockRepo.cannedPosts = [
      _makeTestPost(id: '1', title: 'Golden Retriever', species: 'Dog'),
    ];

    await tester.pumpWidget(_buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🐕 Dogs'));
    await tester.pumpAndSettle();

    expect(controller.species, 'Dog');
    expect(find.text('Species: Dog'), findsOneWidget);
    expect(find.text('Golden Retriever'), findsOneWidget);
  });

  testWidgets('tapping active filter dismiss icon removes the filter', (
    tester,
  ) async {
    controller.setSpecies('Dog');

    await tester.pumpWidget(_buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Species: Dog'), findsOneWidget);

    // Tap the close icon on the active tag
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(controller.species, isNull);
    expect(find.text('Species: Dog'), findsNothing);
  });

  testWidgets('displays empty state when search returns no matching animals', (
    tester,
  ) async {
    mockRepo.cannedPosts = [];

    await tester.pumpWidget(_buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    controller.onQueryChanged('NonExistentAnimal123', immediate: true);
    await tester.pumpAndSettle();

    expect(find.text('No animals found'), findsOneWidget);
    expect(
      find.textContaining('No listed animals match your current search'),
      findsOneWidget,
    );
  });

  testWidgets(
    'displays both recommended and unrecommended animals independently',
    (tester) async {
      mockRepo.cannedPosts = [
        _makeTestPost(id: '1', title: 'Recommended Dog', isRecommended: true),
        _makeTestPost(id: '2', title: 'Other Dog', isRecommended: false),
      ];

      await tester.pumpWidget(_buildTestableWidget(controller: controller));
      await tester.pumpAndSettle();

      controller.setSpecies('Dog');
      await tester.pumpAndSettle();

      expect(find.text('Recommended Dog'), findsOneWidget);
      expect(find.text('Other Dog'), findsOneWidget);
    },
  );
}
