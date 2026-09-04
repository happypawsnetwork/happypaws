import 'package:meta/meta.dart';

enum TransportTaskStatus {
  open,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  completed,
  cancelled,
}

enum TransportOfferStatus { pending, accepted, rejected }

@immutable
class TransportTask {
  final String id;
  final String? transportPostId;
  final String parentPostId;
  final int requesterId;
  final int? transporterId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLon;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLon;
  final DateTime? pickupWindowStart;
  final DateTime? pickupWindowEnd;
  final bool isSelfCollection;
  final TransportTaskStatus status;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportTask({
    required this.id,
    this.transportPostId,
    required this.parentPostId,
    required this.requesterId,
    this.transporterId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLon,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    required this.isSelfCollection,
    required this.status,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class TransportOffer {
  final String id;
  final String transportTaskId;
  final int transporterId;
  final String? message;
  final DateTime proposedPickupStart;
  final DateTime proposedPickupEnd;
  final TransportOfferStatus status;
  final DateTime createdAt;

  const TransportOffer({
    required this.id,
    required this.transportTaskId,
    required this.transporterId,
    this.message,
    required this.proposedPickupStart,
    required this.proposedPickupEnd,
    required this.status,
    required this.createdAt,
  });
}
