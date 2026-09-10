import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/community/presentation/controllers/search_feed_controller.dart';

class MockSearchPostRepository implements IPostRepository {
  List<Post> cannedPosts = [];
  Map<String, dynamic> lastSearchParams = {};
  bool shouldThrow = false;

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
  }) async {
    if (shouldThrow) throw Exception('Network error');
    lastSearchParams = {
      'query': query,
      'species': species,
      'location': location,
      'urgency': urgency,
      'type': type,
      'lat': lat,
      'lon': lon,
      'radiusKm': radiusKm,
      'sort': sort,
      'cursorId': cursorId,
      'cursorDate': cursorDate,
      'pageSize': pageSize,
    };
    return cannedPosts;
  }

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
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
  Future<Post?> getPostById(String id) async => null;

  @override
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async => [];

  @override
  Future<Post> createPost(Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePost(String id) async {}

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async =>
      (isLiked: false, likeCount: 0);

  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async => (urgencyLevel: 'Low', reason: null);
}

Post _createDummyPost({
  required String id,
  required String title,
  String species = 'Dog',
  String urgency = 'High',
  PostType type = PostType.adoptionListing,
  bool isRecommended = false,
}) {
  return Post(
    id: id,
    type: type,
    status: PostStatus.active,
    title: title,
    body: 'Description for $title',
    likeCount: 0,
    isLikedByCurrentUser: false,
    authorId: 1,
    authorDisplayName: 'Foster Care',
    locationLabel: 'Colombo',
    animalSpecies: species,
    animalName: 'Max',
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

  test('initial state is idle with no active filters and empty results', () {
    expect(controller.state, SearchFeedState.idle);
    expect(controller.query, isEmpty);
    expect(controller.hasActiveFilters, isFalse);
    expect(controller.activeFilterCount, 0);
    expect(controller.results, isEmpty);
  });

  test('onQueryChanged triggers search after debounce interval', () async {
    mockRepo.cannedPosts = [
      _createDummyPost(id: '1', title: 'Golden Retriever Mix'),
    ];

    controller.onQueryChanged('Golden');
    expect(controller.state, SearchFeedState.idle);

    // Wait for 400ms debounce
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(controller.state, SearchFeedState.success);
    expect(controller.results.length, 1);
    expect(mockRepo.lastSearchParams['query'], 'Golden');
  });

  test(
    'onQueryChanged with immediate flag triggers search synchronously',
    () async {
      mockRepo.cannedPosts = [_createDummyPost(id: '1', title: 'Fluffy Cat')];

      controller.onQueryChanged('Cat', immediate: true);
      // Even though async, state is loading immediately
      expect(controller.state, SearchFeedState.loading);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state, SearchFeedState.success);
      expect(controller.results.length, 1);
    },
  );

  test('filter management tracks active counts and triggers search', () async {
    mockRepo.cannedPosts = [
      _createDummyPost(id: '1', title: 'Rescue Pup', urgency: 'Critical'),
    ];

    controller.setSpecies('Dog');
    expect(controller.species, 'Dog');
    expect(controller.hasActiveFilters, isTrue);
    expect(controller.activeFilterCount, 1);

    controller.setUrgency('Critical');
    expect(controller.urgency, 'Critical');
    expect(controller.activeFilterCount, 2);

    controller.setLocation('Kandy');
    expect(controller.location, 'Kandy');
    expect(controller.activeFilterCount, 3);

    controller.setType('RescueAlert');
    expect(controller.type, 'RescueAlert');
    expect(controller.activeFilterCount, 4);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(mockRepo.lastSearchParams['species'], 'Dog');
    expect(mockRepo.lastSearchParams['urgency'], 'Critical');
    expect(mockRepo.lastSearchParams['location'], 'Kandy');
    expect(mockRepo.lastSearchParams['type'], 'RescueAlert');
  });

  test('removeFilter removes specific filter and refreshes', () async {
    controller.setSpecies('Dog');
    controller.setUrgency('High');
    expect(controller.activeFilterCount, 2);

    controller.removeFilter('species');
    expect(controller.species, isNull);
    expect(controller.urgency, 'High');
    expect(controller.activeFilterCount, 1);
  });

  test('clearAllFilters resets all filters and returns to idle when query is empty', () async {
    controller.setSpecies('Dog');
    controller.setLocation('Colombo');
    controller.setUrgency('Low');
    expect(controller.hasActiveFilters, isTrue);

    controller.clearAllFilters();
    expect(controller.species, isNull);
    expect(controller.location, isNull);
    expect(controller.urgency, isNull);
    expect(controller.type, isNull);
    expect(controller.onlyRecommended, isFalse);
    expect(controller.hasActiveFilters, isFalse);
    expect(controller.state, SearchFeedState.idle);
  });

  test('matching engine independence: returns both recommended and non-recommended by default', () async {
    mockRepo.cannedPosts = [
      _createDummyPost(id: '1', title: 'Dog 1', isRecommended: true),
      _createDummyPost(id: '2', title: 'Dog 2', isRecommended: false),
    ];

    controller.setSpecies('Dog');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Both are shown by default
    expect(controller.displayedResults.length, 2);

    // When toggling onlyRecommended, narrows to recommended
    controller.setOnlyRecommended(true);
    expect(controller.displayedResults.length, 1);
    expect(controller.displayedResults.first.id, '1');

    // Toggling back shows both again
    controller.setOnlyRecommended(false);
    expect(controller.displayedResults.length, 2);
  });

  test('error state sets errorMessage when repository throws', () async {
    mockRepo.shouldThrow = true;

    controller.onQueryChanged('Puppy', immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state, SearchFeedState.error);
    expect(controller.errorMessage, isNotNull);
  });
}
