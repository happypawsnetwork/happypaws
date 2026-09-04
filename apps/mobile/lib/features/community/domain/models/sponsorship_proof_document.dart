import 'package:meta/meta.dart';

@immutable
class SponsorshipProofDocument {
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String? presignedUrl;
  final DateTime uploadedAt;

  const SponsorshipProofDocument({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    this.presignedUrl,
    required this.uploadedAt,
  });
}
