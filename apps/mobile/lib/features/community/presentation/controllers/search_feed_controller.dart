import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/post.dart';
import '../../domain/repositories/i_post_repository.dart';

enum SearchFeedState { idle, loading, success, error }

/// Manages isolated search and filtering state for animal listings and community posts.
class SearchFeedController extends ChangeNotifier {
  final IPostRepository _repository;

  SearchFeedState _state = SearchFeedState.idle;
  SearchFeedState get state => _state;

  String _query = '';
  String get query => _query;

  String? _species;
  String? get species => _species;

  String? _location;
  String? get location => _location;

  String? _urgency;
  String? get urgency => _urgency;

  String? _type;
  String? get type => _type;

  bool _onlyRecommended = false;
  bool get onlyRecommended => _onlyRecommended;

  double? _lat;
  double? get lat => _lat;

  double? _lon;
  double? get lon => _lon;

  double? _radiusKm;
  double? get radiusKm => _radiusKm;

  String _sort = 'newest';
  String get sort => _sort;

  List<Post> _results = [];
  List<Post> get results => _results;

  List<Post> get displayedResults {
    if (_onlyRecommended) {
      return _results.where((p) => p.isRecommended).toList();
    }
    return _results;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Timer? _debounceTimer;

  SearchFeedController(this._repository);

  bool get hasActiveFilters {
    final hasSpecies =
        _species != null &&
        _species!.isNotEmpty &&
        _species!.toLowerCase() != 'all';
    final hasLocation = _location != null && _location!.trim().isNotEmpty;
    final hasUrgency =
        _urgency != null &&
        _urgency!.isNotEmpty &&
        _urgency!.toLowerCase() != 'all';
    final hasType =
        _type != null && _type!.isNotEmpty && _type!.toLowerCase() != 'all';
    return hasSpecies ||
        hasLocation ||
        hasUrgency ||
        hasType ||
        _onlyRecommended;
  }

  int get activeFilterCount {
    int count = 0;
    if (_species != null &&
        _species!.isNotEmpty &&
        _species!.toLowerCase() != 'all')
      count++;
    if (_location != null && _location!.trim().isNotEmpty) count++;
    if (_urgency != null &&
        _urgency!.isNotEmpty &&
        _urgency!.toLowerCase() != 'all')
      count++;
    if (_type != null && _type!.isNotEmpty && _type!.toLowerCase() != 'all')
      count++;
    if (_onlyRecommended) count++;
    return count;
  }

  void onQueryChanged(String newQuery, {bool immediate = false}) {
    _query = newQuery;
    _debounceTimer?.cancel();

    if (immediate) {
      performSearch();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        performSearch();
      });
    }
  }

  void setSpecies(String? val) {
    if (_species == val) return;
    _species = (val == null || val.toLowerCase() == 'all') ? null : val;
    notifyListeners();
    performSearch();
  }

  void setLocation(String? val) {
    if (_location == val) return;
    _location = (val == null || val.trim().isEmpty) ? null : val.trim();
    notifyListeners();
    performSearch();
  }

  void setGeoLocation({double? lat, double? lon, double? radiusKm}) {
    _lat = lat;
    _lon = lon;
    _radiusKm = radiusKm;
    notifyListeners();
    performSearch();
  }

  void setUrgency(String? val) {
    if (_urgency == val) return;
    _urgency = (val == null || val.toLowerCase() == 'all') ? null : val;
    notifyListeners();
    performSearch();
  }

  void setType(String? val) {
    if (_type == val) return;
    _type = (val == null || val.toLowerCase() == 'all') ? null : val;
    notifyListeners();
    performSearch();
  }

  void setOnlyRecommended(bool val) {
    if (_onlyRecommended == val) return;
    _onlyRecommended = val;
    notifyListeners();
  }

  void setSort(String newSort) {
    if (_sort == newSort) return;
    _sort = newSort;
    notifyListeners();
    performSearch();
  }

  void applyFilters({
    String? species,
    String? location,
    String? urgency,
    String? type,
    bool? onlyRecommended,
  }) {
    _species = (species == null || species.toLowerCase() == 'all')
        ? null
        : species;
    _location = (location == null || location.trim().isEmpty)
        ? null
        : location.trim();
    _urgency = (urgency == null || urgency.toLowerCase() == 'all')
        ? null
        : urgency;
    _type = (type == null || type.toLowerCase() == 'all') ? null : type;
    if (onlyRecommended != null) {
      _onlyRecommended = onlyRecommended;
    }
    notifyListeners();
    performSearch();
  }

  void removeFilter(String filterKey) {
    switch (filterKey) {
      case 'species':
        _species = null;
        break;
      case 'location':
        _location = null;
        _lat = null;
        _lon = null;
        _radiusKm = null;
        break;
      case 'urgency':
        _urgency = null;
        break;
      case 'type':
        _type = null;
        break;
      case 'recommended':
        _onlyRecommended = false;
        break;
    }
    notifyListeners();
    performSearch();
  }

  void clearAllFilters() {
    _species = null;
    _location = null;
    _lat = null;
    _lon = null;
    _radiusKm = null;
    _urgency = null;
    _type = null;
    _onlyRecommended = false;
    notifyListeners();
    performSearch();
  }

  Future<void> performSearch({bool isRefresh = false}) async {
    _debounceTimer?.cancel();

    // If query is empty and no filters are set, clear results and set to idle
    if (_query.trim().isEmpty && !hasActiveFilters) {
      _results = [];
      _state = SearchFeedState.idle;
      _hasMore = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _state = SearchFeedState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.searchPosts(
        query: _query.trim().isNotEmpty ? _query.trim() : null,
        species: _species,
        location: _location,
        urgency: _urgency,
        type: _type,
        lat: _lat,
        lon: _lon,
        radiusKm: _radiusKm,
        sort: _sort,
        pageSize: 20,
      );
      _results = fetched;
      _hasMore = fetched.length >= 20;
      _state = SearchFeedState.success;
      notifyListeners();
    } catch (e) {
      _state = SearchFeedState.error;
      _errorMessage = 'Failed to load search results. Please try again.';
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _results.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final lastId = _results.last.id;
      final lastDate = _results.last.createdAt;

      final more = await _repository.searchPosts(
        query: _query.trim().isNotEmpty ? _query.trim() : null,
        species: _species,
        location: _location,
        urgency: _urgency,
        type: _type,
        lat: _lat,
        lon: _lon,
        radiusKm: _radiusKm,
        sort: _sort,
        cursorId: lastId,
        cursorDate: lastDate,
        pageSize: 20,
      );

      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _results.addAll(more);
        _hasMore = more.length >= 20;
      }
    } catch (_) {
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
