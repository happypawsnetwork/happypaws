class PostDetailDto {
  final String id;
  final String type;
  final String status;
  final String title;
  final String body;
  final int likeCount;
  final bool isLikedByCurrentUser;
  final int authorId;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final String? animalSpecies;
  final String? animalName;
  final String? animalDescription;
  final int photoCount;
  final String? parentPostId;
  final String? parentPostTitle;
  final int? applicantCount;
  final Map<String, dynamic>? vetDetails;
  final Map<String, dynamic>? sponsorshipDetails;
  final List<dynamic> media;
  final DateTime createdAt;

  PostDetailDto({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    required this.likeCount,
    required this.isLikedByCurrentUser,
    required this.authorId,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.animalSpecies,
    this.animalName,
    this.animalDescription,
    required this.photoCount,
    this.parentPostId,
    this.parentPostTitle,
    this.applicantCount,
    this.vetDetails,
    this.sponsorshipDetails,
    required this.media,
    required this.createdAt,
  });

  factory PostDetailDto.fromJson(Map<String, dynamic> json) {
    return PostDetailDto(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      likeCount: json['likeCount'] as int,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool,
      authorId: json['authorId'] as int,
      authorDisplayName: json['authorDisplayName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      locationLabel: json['locationLabel'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      animalSpecies: json['animalSpecies'] as String?,
      animalName: json['animalName'] as String?,
      animalDescription: json['animalDescription'] as String?,
      photoCount: json['photoCount'] as int,
      parentPostId: json['parentPostId'] as String?,
      parentPostTitle: json['parentPostTitle'] as String?,
      applicantCount: json['applicantCount'] as int?,
      vetDetails: json['vetDetails'] as Map<String, dynamic>?,
      sponsorshipDetails: json['sponsorshipDetails'] as Map<String, dynamic>?,
      media: json['media'] as List<dynamic>? ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
