import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";
import "package:mobile/features/profile/domain/models/role_verification_status.dart";
import "package:mobile/features/profile/domain/repositories/i_verification_repository.dart";
import "package:mobile/features/profile/presentation/controllers/verification_controller.dart";
import "package:mobile/features/profile/presentation/screens/verification_upload_screen.dart";

class FakeVerificationRepository implements IVerificationRepository {
  @override
  Future<List<RoleVerificationStatus>> getVerificationStatuses() async => [];

  @override
  Future<String> uploadDocument({
    required File file,
    required String documentType,
  }) async => "mock-uri";

  @override
  Future<void> submitVerification({
    required String requestedRole,
    required List<Map<String, String>> documents,
  }) async {}
}

void main() {
  testWidgets(
    "renders VerificationUploadScreen with required document cards for selected role",
    (tester) async {
      final fakeRepo = FakeVerificationRepository();
      final controller = VerificationController(fakeRepo);
      controller.selectRole("Transporter");

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VerificationController>.value(
            value: controller,
            child: const VerificationUploadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Transporter Verification"), findsOneWidget);
      expect(find.text("Driving License"), findsOneWidget);
      expect(find.text("Vehicle Insurance"), findsOneWidget);
      expect(find.text("Submit Documents"), findsOneWidget);
    },
  );
}
