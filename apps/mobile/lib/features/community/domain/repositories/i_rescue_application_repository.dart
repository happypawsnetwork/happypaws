import '../models/rescue_application.dart';

abstract interface class IRescueApplicationRepository {
  Future<List<RescueApplication>> getApplicants(String postId);
  Future<List<RescueApplication>> getMyRescues();
  Future<void> submitApplication(String postId, Map<String, dynamic> data);
  Future<void> reviewApplication(String applicationId, bool approve);
  Future<void> adminOverride(String applicationId);
}
