import '../models/transport_task.dart';

abstract interface class ITransportRepository {
  Future<TransportTask> getTaskById(String taskId);
  Future<List<TransportTask>> getMyTransports();
  Future<void> createTask(Map<String, dynamic> data);
  Future<void> submitOffer(String taskId, Map<String, dynamic> data);
  Future<void> acceptOffer(String offerId);
  Future<void> updateStatus(String taskId, TransportTaskStatus status);
  Future<void> confirmDelivery(String taskId);
  Future<void> markSelfCollected(String taskId);
  Future<void> closeRescueCase(String taskId);
}
