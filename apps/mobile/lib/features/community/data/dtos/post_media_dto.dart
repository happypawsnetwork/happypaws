class PostMediaDto {
  final String id;
  final String cdnUrl;
  final String mimeType;
  final int sortOrder;

  PostMediaDto({
    required this.id,
    required this.cdnUrl,
    required this.mimeType,
    required this.sortOrder,
  });

  factory PostMediaDto.fromJson(Map<String, dynamic> json) {
    return PostMediaDto(
      id: json['id'] as String,
      cdnUrl: json['cdnUrl'] as String,
      mimeType: json['mimeType'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }
}
