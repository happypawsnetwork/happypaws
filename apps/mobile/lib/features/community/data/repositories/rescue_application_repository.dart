import '../../../../core/network/api_client.dart';
import '../../domain/models/rescue_application.dart';
import '../../domain/repositories/i_rescue_application_repository.dart';

class RescueApplicationRepository implements IRescueApplicationRepository {
  final ApiClient _apiClient;

  RescueApplicationRepository(this._apiClient);

  @override
  Future<List<RescueApplication>> getApplicants(String postId) async {
    await _apiClient.get('/api/v1/community/posts/$postId/rescue-applications');
    return []; // Map in actual implementation
  }

  @override
  Future<List<RescueApplication>> getMyRescues() async {
    await _apiClient.get('/api/v1/community/my-rescues');
    return [];
  }

  @override
  Future<void> submitApplication(
    String postId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.post(
      '/api/v1/community/posts/$postId/rescue-applications',
      body: data,
    );
  }

  @override
  Future<void> reviewApplication(String applicationId, bool approve) async {
    await _apiClient.post(
      '/api/v1/community/rescue-applications/$applicationId/review',
      body: {'approve': approve},
    );
  }

  @override
  Future<void> adminOverride(String applicationId) async {
    await _apiClient.post(
      '/api/v1/community/rescue-applications/$applicationId/override',
    );
  }
}
