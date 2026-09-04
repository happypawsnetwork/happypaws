import 'package:meta/meta.dart';

import '../../../../core/utils/url_helper.dart';
import '../../../community/data/repositories/post_repository.dart';
import '../../../community/domain/models/post.dart';

@immutable
class PublicUserProfile {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final String? tagline;
  final String? username;
  final int reputationPoints;
  final List<String> roles;
  final DateTime createdAt;
  final List<Post> posts;
  final bool canMessage;

  const PublicUserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.tagline,
    this.username,
    required this.reputationPoints,
    required this.roles,
    required this.createdAt,
    required this.posts,
    this.canMessage = true,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] as List<dynamic>? ?? [];
    final parsedPosts = rawPosts
        .map((p) => PostRepository.mapJsonToPost(p as Map<String, dynamic>))
        .toList();

    return PublicUserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? 'User',
      avatarUrl: UrlHelper.resolveUrl(json['avatarUrl'] as String?),
      tagline: json['tagline'] as String?,
      username: json['username'] as String?,
      reputationPoints: (json['reputationPoints'] as num?)?.toInt() ?? 0,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      posts: parsedPosts,
      canMessage: json['canMessage'] as bool? ?? true,
    );
  }
}
