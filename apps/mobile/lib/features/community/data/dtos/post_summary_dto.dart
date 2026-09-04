class PostSummaryDto {
  final String id;
  final String type;
  final String status;
  final String title;
  final String? firstPhotoCdnUrl;
  final int likeCount;
  final DateTime createdAt;
  final String authorDisplayName;
  final String? locationLabel;
  final String? animalSpecies;

  PostSummaryDto({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.firstPhotoCdnUrl,
    required this.likeCount,
    required this.createdAt,
    required this.authorDisplayName,
    this.locationLabel,
    this.animalSpecies,
  });

  factory PostSummaryDto.fromJson(Map<String, dynamic> json) {
    return PostSummaryDto(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      firstPhotoCdnUrl: json['firstPhotoCdnUrl'] as String?,
      likeCount: json['likeCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorDisplayName: json['authorDisplayName'] as String,
      locationLabel: json['locationLabel'] as String?,
      animalSpecies: json['animalSpecies'] as String?,
    );
  }
}
