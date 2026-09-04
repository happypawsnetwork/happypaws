import '../models/sponsorship_details.dart';
import '../models/sponsorship_proof_document.dart';

abstract interface class ISponsorshipRepository {
  Future<List<SponsorshipDetails>> getAdminSponsorships();
  Future<List<SponsorshipProofDocument>> getProofDocuments(String postId);
  Future<void> createSponsorship(Map<String, dynamic> data);
  Future<void> adminReview(String postId, bool approve, String? notes);
  Future<void> markFunded(String postId);
  Future<void> close(String postId);
}
