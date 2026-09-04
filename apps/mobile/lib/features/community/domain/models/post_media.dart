import 'package:meta/meta.dart';

@immutable
class PostMedia {
  final String id;
  final String cdnUrl;
  final String mimeType;
  final int sortOrder;

  const PostMedia({
    required this.id,
    required this.cdnUrl,
    required this.mimeType,
    required this.sortOrder,
  });
}
