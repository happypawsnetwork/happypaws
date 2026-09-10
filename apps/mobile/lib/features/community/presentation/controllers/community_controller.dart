import 'package:flutter/material.dart';

import '../../domain/models/post.dart';
import '../../domain/repositories/i_post_repository.dart';

enum CommunityState { idle, loading, success, error }

class CommunityController extends ChangeNotifier {
  final IPostRepository _repository;

  CommunityState _state = CommunityState.idle;
  CommunityState get state => _state;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  List<Post> _nearbyPosts = [];
  List<Post> get nearbyPosts => _nearbyPosts;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _selectedType;
  String? get selectedType => _selectedType;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _nearbyHasMore = true;
  bool get nearbyHasMore => _nearbyHasMore;

  bool _nearbyIsLoadingMore = false;
  bool get nearbyIsLoadingMore => _nearbyIsLoadingMore;

  double? _lastLat;
  double? _lastLon;

  CommunityController(this._repository);

  Future<void> loadFeed({bool isRefresh = false}) async {
    if (!isRefresh) {
      _state = CommunityState.loading;
      notifyListeners();
    } else {
      _hasMore = true;
    }

    try {
      _posts = await _repository.getCommunityFeed(type: _selectedType);
      _hasMore = _posts.length >= 10;
      _state = CommunityState.success;
      notifyListeners();
    } catch (e) {
      _state = CommunityState.error;
      _errorMessage = 'Failed to load community feed.';
      notifyListeners();
    }
  }

  Future<void> searchFeed(String query) async {
    _state = CommunityState.loading;
    _hasMore = false;
    notifyListeners();

    try {
      _posts = await _repository.searchPosts(query: query);
      _state = CommunityState.success;
      notifyListeners();
    } catch (e) {
      _state = CommunityState.error;
      _errorMessage = 'Failed to search posts.';
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final lastId = _posts.isNotEmpty ? _posts.last.id : null;
      final lastDate = _posts.isNotEmpty ? _posts.last.createdAt : null;
      final morePosts = await _repository.getCommunityFeed(
        type: _selectedType,
        cursorId: lastId,
        cursorDate: lastDate,
      );
      if (morePosts.isEmpty) {
        _hasMore = false;
      } else {
        _posts.addAll(morePosts);
        _hasMore = morePosts.length >= 10;
      }
    } catch (e) {
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyFeed(
    double lat,
    double lon, {
    bool isRefresh = false,
  }) async {
    _lastLat = lat;
    _lastLon = lon;
    if (!isRefresh) {
      _state = CommunityState.loading;
      notifyListeners();
    } else {
      _nearbyHasMore = true;
    }

    try {
      _nearbyPosts = await _repository.getNearbyFeed(
        lat: lat,
        lon: lon,
        radiusKm: 10,
      );
      // We will filter by type manually or update getNearbyFeed later, wait getNearbyFeed doesn't accept type yet
      _nearbyPosts = _selectedType != null
          ? _nearbyPosts
                .where(
                  (p) =>
                      p.type.name.toLowerCase() == _selectedType!.toLowerCase(),
                )
                .toList()
          : _nearbyPosts;
      _nearbyHasMore = _nearbyPosts.length >= 10;
      _state = CommunityState.success;
      notifyListeners();
    } catch (e) {
      _state = CommunityState.error;
      _errorMessage = 'Failed to load nearby feed.';
      notifyListeners();
    }
  }

  Future<void> loadMoreNearby() async {
    if (_nearbyIsLoadingMore ||
        !_nearbyHasMore ||
        _lastLat == null ||
        _lastLon == null) {
      return;
    }

    _nearbyIsLoadingMore = true;
    notifyListeners();

    try {
      final lastId = _nearbyPosts.isNotEmpty ? _nearbyPosts.last.id : null;
      final lastDate = _nearbyPosts.isNotEmpty
          ? _nearbyPosts.last.createdAt
          : null;
      var morePosts = await _repository.getNearbyFeed(
        lat: _lastLat!,
        lon: _lastLon!,
        radiusKm: 10,
        cursorId: lastId,
        cursorDate: lastDate,
      );
      morePosts = _selectedType != null
          ? morePosts
                .where(
                  (p) =>
                      p.type.name.toLowerCase() == _selectedType!.toLowerCase(),
                )
                .toList()
          : morePosts;
      if (morePosts.isEmpty) {
        _nearbyHasMore = false;
      } else {
        _nearbyPosts.addAll(morePosts);
        _nearbyHasMore = morePosts.length >= 10;
      }
    } catch (e) {
      _nearbyHasMore = false;
    } finally {
      _nearbyIsLoadingMore = false;
      notifyListeners();
    }
  }

  void setTypeFilter(String? type, {bool isNearby = false}) {
    if (_selectedType == type) return;
    _selectedType = type;
    if (isNearby) {
      if (_lastLat != null && _lastLon != null) {
        loadNearbyFeed(_lastLat!, _lastLon!);
      }
    } else {
      loadFeed();
    }
  }

  Future<void> toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    final nearbyIndex = _nearbyPosts.indexWhere((p) => p.id == postId);

    if (postIndex == -1 && nearbyIndex == -1) return;

    final targetPost = postIndex != -1
        ? _posts[postIndex]
        : _nearbyPosts[nearbyIndex];
    final bool currentlyLiked = targetPost.isLikedByCurrentUser;
    final int newCount = currentlyLiked
        ? targetPost.likeCount - 1
        : targetPost.likeCount + 1;
    final bool newLiked = !currentlyLiked;

    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        isLikedByCurrentUser: newLiked,
        likeCount: newCount < 0 ? 0 : newCount,
      );
    }
    if (nearbyIndex != -1) {
      _nearbyPosts[nearbyIndex] = _nearbyPosts[nearbyIndex].copyWith(
        isLikedByCurrentUser: newLiked,
        likeCount: newCount < 0 ? 0 : newCount,
      );
    }
    notifyListeners();

    try {
      final result = await _repository.toggleLike(postId);
      if (postIndex != -1 && postIndex < _posts.length) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          isLikedByCurrentUser: result.isLiked,
          likeCount: result.likeCount,
        );
      }
      if (nearbyIndex != -1 && nearbyIndex < _nearbyPosts.length) {
        _nearbyPosts[nearbyIndex] = _nearbyPosts[nearbyIndex].copyWith(
          isLikedByCurrentUser: result.isLiked,
          likeCount: result.likeCount,
        );
      }
      notifyListeners();
    } catch (e) {
      if (postIndex != -1 && postIndex < _posts.length) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          isLikedByCurrentUser: currentlyLiked,
          likeCount: targetPost.likeCount,
        );
      }
      if (nearbyIndex != -1 && nearbyIndex < _nearbyPosts.length) {
        _nearbyPosts[nearbyIndex] = _nearbyPosts[nearbyIndex].copyWith(
          isLikedByCurrentUser: currentlyLiked,
          likeCount: targetPost.likeCount,
        );
      }
      notifyListeners();
    }
  }

  void updatePostLikeState(String postId, bool isLiked, int likeCount) {
    bool changed = false;
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        isLikedByCurrentUser: isLiked,
        likeCount: likeCount,
      );
      changed = true;
    }
    final nearbyIndex = _nearbyPosts.indexWhere((p) => p.id == postId);
    if (nearbyIndex != -1) {
      _nearbyPosts[nearbyIndex] = _nearbyPosts[nearbyIndex].copyWith(
        isLikedByCurrentUser: isLiked,
        likeCount: likeCount,
      );
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}
