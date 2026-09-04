import '../../../../core/network/api_client.dart';
import '../../domain/models/transport_task.dart';
import '../../domain/repositories/i_transport_repository.dart';

class TransportRepository implements ITransportRepository {
  final ApiClient _apiClient;

  TransportRepository(this._apiClient);

  @override
  Future<TransportTask> getTaskById(String taskId) async {
    await _apiClient.get('/api/v1/community/transport-tasks/$taskId');
    throw UnimplementedError('Mapping not fully implemented for mock');
  }

  @override
  Future<List<TransportTask>> getMyTransports() async {
    await _apiClient.get('/api/v1/community/transport-tasks/me');
    return [];
  }

  @override
  Future<void> createTask(Map<String, dynamic> data) async {
    await _apiClient.post('/api/v1/community/transport-tasks', body: data);
  }

  @override
  Future<void> submitOffer(String taskId, Map<String, dynamic> data) async {
    await _apiClient.post(
      '/api/v1/community/transport-tasks/$taskId/offers',
      body: data,
    );
  }

  @override
  Future<void> acceptOffer(String offerId) async {
    await _apiClient.post('/api/v1/community/transport-offers/$offerId/accept');
  }

  @override
  Future<void> updateStatus(String taskId, TransportTaskStatus status) async {
    await _apiClient.post(
      '/api/v1/community/transport-tasks/$taskId/status',
      body: {'status': status.name},
    );
  }

  @override
  Future<void> confirmDelivery(String taskId) async {
    await _apiClient.post('/api/v1/community/transport-tasks/$taskId/confirm');
  }

  @override
  Future<void> markSelfCollected(String taskId) async {
    await _apiClient.post(
      '/api/v1/community/transport-tasks/$taskId/self-collect',
    );
  }

  @override
  Future<void> closeRescueCase(String taskId) async {
    await _apiClient.post(
      '/api/v1/community/transport-tasks/$taskId/close-rescue',
    );
  }
}
