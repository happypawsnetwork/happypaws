import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/models/post.dart';
import '../../domain/models/post_media.dart';
import '../../domain/models/lifestyle_expectations.dart';
import '../../domain/repositories/i_post_repository.dart';

class PostRepository implements IPostRepository {
  final ApiClient _apiClient;

  PostRepository(this._apiClient);

  static PostType parseType(String typeStr) {
    switch (typeStr) {
      case 'RescueAlert':
        return PostType.rescueAlert;
      case 'FosterUpdate':
        return PostType.fosterUpdate;
      case 'AdoptionListing':
        return PostType.adoptionListing;
      case 'Highlight':
        return PostType.highlight;
      case 'TransportRequest':
        return PostType.transportRequest;
      case 'VetRequest':
        return PostType.vetRequest;
      case 'SponsorshipRequest':
        return PostType.sponsorshipRequest;
      default:
        return PostType.highlight;
    }
  }

  static PostStatus parseStatus(String statusStr) {
    switch (statusStr) {
      case 'Active':
        return PostStatus.active;
      case 'Fostered':
        return PostStatus.fostered;
      case 'Assigned':
        return PostStatus.assigned;
      case 'Completed':
        return PostStatus.completed;
      case 'PendingApproval':
        return PostStatus.pendingApproval;
      case 'Funded':
        return PostStatus.funded;
      case 'Rejected':
        return PostStatus.rejected;
      case 'Cancelled':
        return PostStatus.cancelled;
      default:
        return PostStatus.active;
    }
  }

  static Post mapJsonToPost(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      type: parseType(json['type'] as String),
      status: parseStatus(json['status'] as String),
      title: json['title'] as String,
      body: json['body'] ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      authorId: json['authorId'] as int? ?? 0,
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Unknown',
      authorAvatarUrl: UrlHelper.resolveUrl(json['authorAvatarUrl'] as String?),
      authorTagline:
          json['authorTagline'] as String? ?? json['authorBio'] as String?,
      locationLabel: json['locationLabel'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      animalSpecies: json['animalSpecies'] as String?,
      animalName: json['animalName'] as String?,
      photoCount: json['photoCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      firstPhotoUrl: UrlHelper.resolveUrl(
        json['firstPhotoUrl'] as String? ?? json['firstPhotoCdnUrl'] as String?,
      ),
      urgencyLevel: json['urgencyLevel'] as String?,
      aiTriageReason: json['aiTriageReason'] as String?,
      isUrgencyManuallyOverridden:
          json['isUrgencyManuallyOverridden'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
      isAuthorVerified: json['isAuthorVerified'] as bool? ?? false,
      expectations: json['expectations'] != null
          ? LifestyleExpectations.fromJson(
              json['expectations'] as Map<String, dynamic>,
            )
          : null,
      media:
          (json['media'] as List<dynamic>?)
              ?.map(
                (m) => PostMedia(
                  id: m['id'] as String? ?? '',
                  cdnUrl:
                      UrlHelper.resolveUrl(m['cdnUrl'] as String? ?? '') ?? '',
                  mimeType: m['mimeType'] as String? ?? '',
                  sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
                ),
              )
              .toList() ??
          [],
    );
  }

  Post _mapDtoToPost(Map<String, dynamic> json) => mapJsonToPost(json);

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
    int pageSize = 10,
  }) async {
    final query = <String, String>{
      'sort': sort,
      'pageSize': pageSize.toString(),
    };
    if (type != null) query['type'] = type;
    if (cursorId != null) query['cursorId'] = cursorId;
    if (cursorDate != null) query['cursorDate'] = cursorDate.toIso8601String();

    final response = await _apiClient.get(
      '/api/v1/community/posts?${Uri(queryParameters: query).query}',
    );
    final items = (response is List)
        ? response
        : (response?['items'] as List<dynamic>? ?? []);
    return items.map((e) => _mapDtoToPost(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
    int pageSize = 10,
  }) async {
    final query = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radiusKm': radiusKm.toString(),
      'pageSize': pageSize.toString(),
    };
    if (cursorId != null) query['cursorId'] = cursorId;
    if (cursorDate != null) query['cursorDate'] = cursorDate.toIso8601String();

    final response = await _apiClient.get(
      '/api/v1/community/posts/nearby?${Uri(queryParameters: query).query}',
    );
    final items = (response is List)
        ? response
        : (response?['items'] as List<dynamic>? ?? []);
    return items.map((e) => _mapDtoToPost(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Post>> getMapBoundsFeed({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    String? type,
  }) async {
    final query = <String, String>{
      'swLat': swLat.toString(),
      'swLon': swLon.toString(),
      'neLat': neLat.toString(),
      'neLon': neLon.toString(),
    };
    if (type != null) query['type'] = type;

    final response = await _apiClient.get(
      '/api/v1/community/posts/map-bounds?${Uri(queryParameters: query).query}',
    );
    final items = (response is List)
        ? response
        : (response?['items'] as List<dynamic>? ?? []);
    return items.map((e) => _mapDtoToPost(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Post?> getPostById(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/community/posts/$id');
      return _mapDtoToPost(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

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
    final queryParams = <String, String>{
      'sort': sort,
      'pageSize': pageSize.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (species != null &&
        species.trim().isNotEmpty &&
        species.toLowerCase() != 'all') {
      queryParams['species'] = species.trim();
    }
    if (location != null &&
        location.trim().isNotEmpty &&
        location.toLowerCase() != 'all') {
      queryParams['location'] = location.trim();
    }
    if (urgency != null &&
        urgency.trim().isNotEmpty &&
        urgency.toLowerCase() != 'all') {
      queryParams['urgency'] = urgency.trim();
    }
    if (type != null && type.trim().isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.trim();
    }
    if (lat != null && lon != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lon'] = lon.toString();
      if (radiusKm != null) {
        queryParams['radiusKm'] = radiusKm.toString();
      }
    }
    if (cursorId != null) queryParams['cursorId'] = cursorId;
    if (cursorDate != null) {
      queryParams['cursorDate'] = cursorDate.toIso8601String();
    }

    final response = await _apiClient.get(
      '/api/v1/community/search?${Uri(queryParameters: queryParams).query}',
    );
    final items = (response is List)
        ? response
        : (response?['items'] as List<dynamic>? ?? []);
    return items
        .map((json) => _mapDtoToPost(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async {
    final response = await _apiClient.get('/api/v1/community/posts/me');
    final items = (response is List)
        ? response
        : (response?['items'] as List<dynamic>? ?? []);
    return items.map((e) => _mapDtoToPost(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async {
    try {
      final response = await _apiClient.get('/api/v1/community/my-rescues');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Post> createPost(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/api/v1/community/posts',
      body: data,
    );
    return _mapDtoToPost(response as Map<String, dynamic>);
  }

  @override
  Future<void> deletePost(String id) async {
    await _apiClient.delete('/api/v1/community/posts/$id');
  }

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async {
    final response = await _apiClient.post(
      '/api/v1/community/posts/$postId/like',
    );
    return (
      isLiked: response['isLiked'] as bool,
      likeCount: response['likeCount'] as int,
    );
  }

  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async {
    if (photoPaths.isEmpty) return (urgencyLevel: 'Medium', reason: null);
    try {
      final response = await _apiClient.multipart(
        '/api/v1/community/rescue-triage/assess',
        files: photoPaths.take(3).map((p) => File(p)).toList(),
        fieldName: 'photos',
      );
      return (
        urgencyLevel: response?['urgencyLevel'] as String? ?? 'Medium',
        reason: response?['reason'] as String?,
      );
    } catch (e) {
      return (urgencyLevel: 'Medium', reason: null);
    }
  }
}
