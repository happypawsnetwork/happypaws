import 'package:meta/meta.dart';

@immutable
class VetRequestDetails {
  final String reasonForVisit;
  final String? clinicName;
  final DateTime? appointmentDate;
  final bool transportNeeded;

  const VetRequestDetails({
    required this.reasonForVisit,
    this.clinicName,
    this.appointmentDate,
    required this.transportNeeded,
  });
}
