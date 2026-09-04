import 'package:meta/meta.dart';

@immutable
class SponsorshipDetails {
  final String goalDescription;
  final double? estimatedAmountLkr;
  final String? adminRejectionNotes;
  final DateTime? fundedAt;
  final int proofDocumentCount;

  const SponsorshipDetails({
    required this.goalDescription,
    this.estimatedAmountLkr,
    this.adminRejectionNotes,
    this.fundedAt,
    required this.proofDocumentCount,
  });
}
