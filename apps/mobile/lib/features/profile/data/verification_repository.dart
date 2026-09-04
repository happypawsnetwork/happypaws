import "dart:io";

import "../../../core/network/api_client.dart";
import "../domain/models/role_verification_status.dart";
import "../domain/repositories/i_verification_repository.dart";

class VerificationRepository implements IVerificationRepository {
  final ApiClient _apiClient;

  VerificationRepository(this._apiClient);

  @override
  Future<List<RoleVerificationStatus>> getVerificationStatuses() async {
    final response = await _apiClient.get("/api/verification/status");
    if (response is Map &&
        response.containsKey("roles") &&
        response["roles"] is List) {
      return (response["roles"] as List)
          .map(
            (item) =>
                RoleVerificationStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<String> uploadDocument({
    required File file,
    required String documentType,
  }) async {
    final response = await _apiClient.multipart(
      "/api/verification/upload?documentType=$documentType",
      files: [file],
    );
    if (response is Map && response.containsKey("documentUri")) {
      return response["documentUri"] as String;
    }
    throw Exception("Failed to get uploaded document URI");
  }

  @override
  Future<void> submitVerification({
    required String requestedRole,
    required List<Map<String, String>> documents,
  }) async {
    await _apiClient.post(
      "/api/verification/submit",
      body: {"requestedRole": requestedRole, "documents": documents},
    );
  }
}
