import '../../../../core/network/api_client.dart';
import '../../domain/models/sponsorship_details.dart';
import '../../domain/models/sponsorship_proof_document.dart';
import '../../domain/repositories/i_sponsorship_repository.dart';

class SponsorshipRepository implements ISponsorshipRepository {
  final ApiClient _apiClient;

  SponsorshipRepository(this._apiClient);

  @override
  Future<List<SponsorshipDetails>> getAdminSponsorships() async {
    await _apiClient.get('/api/v1/community/sponsorships/admin');
    return [];
  }

  @override
  Future<List<SponsorshipProofDocument>> getProofDocuments(
    String postId,
  ) async {
    await _apiClient.get('/api/v1/community/posts/$postId/sponsorship-proofs');
    return [];
  }

  @override
  Future<void> createSponsorship(Map<String, dynamic> data) async {
    await _apiClient.post('/api/v1/community/sponsorships', body: data);
  }

  @override
  Future<void> adminReview(String postId, bool approve, String? notes) async {
    await _apiClient.post(
      '/api/v1/community/sponsorships/$postId/review',
      body: {'approve': approve, 'notes': notes},
    );
  }

  @override
  Future<void> markFunded(String postId) async {
    await _apiClient.post('/api/v1/community/sponsorships/$postId/mark-funded');
  }

  @override
  Future<void> close(String postId) async {
    await _apiClient.post('/api/v1/community/sponsorships/$postId/close');
  }
}
