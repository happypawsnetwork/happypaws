import "dart:io";

import "../models/role_verification_status.dart";

abstract class IVerificationRepository {
  Future<List<RoleVerificationStatus>> getVerificationStatuses();
  Future<String> uploadDocument({
    required File file,
    required String documentType,
  });
  Future<void> submitVerification({
    required String requestedRole,
    required List<Map<String, String>> documents,
  });
}
