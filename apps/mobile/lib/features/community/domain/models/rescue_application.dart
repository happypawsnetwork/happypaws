import 'package:meta/meta.dart';

enum RescueApplicationStatus { pending, approved, rejected, adminOverridden }

enum ApplicantRole { foster, adopter }

@immutable
class RescueApplication {
  final String id;
  final String rescuePostId;
  final int applicantId;
  final ApplicantRole applicantRole;
  final String? message;
  final String? experienceSummary;
  final bool hasVehicle;
  final RescueApplicationStatus status;
  final DateTime? posterReviewedAt;
  final DateTime? adminReviewedAt;
  final int? adminReviewerId;
  final DateTime createdAt;

  const RescueApplication({
    required this.id,
    required this.rescuePostId,
    required this.applicantId,
    required this.applicantRole,
    this.message,
    this.experienceSummary,
    required this.hasVehicle,
    required this.status,
    this.posterReviewedAt,
    this.adminReviewedAt,
    this.adminReviewerId,
    required this.createdAt,
  });
}
