import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";
import "package:mobile/features/profile/domain/models/role_verification_status.dart";
import "package:mobile/features/profile/domain/repositories/i_verification_repository.dart";
import "package:mobile/features/profile/presentation/controllers/verification_controller.dart";
import "package:mobile/features/profile/presentation/screens/verification_role_selection_screen.dart";

import "dart:io";

class FakeVerificationRepository implements IVerificationRepository {
  @override
  Future<List<RoleVerificationStatus>> getVerificationStatuses() async {
    return [
      const RoleVerificationStatus(role: "Adopter", status: "Verified"),
      const RoleVerificationStatus(role: "Foster", status: "Unverified"),
      const RoleVerificationStatus(role: "Transporter", status: "Unverified"),
      const RoleVerificationStatus(role: "Veterinarian", status: "Unverified"),
      const RoleVerificationStatus(role: "Sponsor", status: "Unverified"),
    ];
  }

  @override
  Future<String> uploadDocument({
    required File file,
    required String documentType,
  }) async {
    return "test-uri";
  }

  @override
  Future<void> submitVerification({
    required String requestedRole,
    required List<Map<String, String>> documents,
  }) async {}
}

void main() {
  testWidgets(
    "renders VerificationRoleSelectionScreen and disables already verified roles",
    (tester) async {
      final fakeRepo = FakeVerificationRepository();
      final controller = VerificationController(fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VerificationController>.value(
            value: controller,
            child: const VerificationRoleSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Identity verification"), findsOneWidget);
      expect(find.text("Select Role"), findsNWidgets(2));
      expect(find.text("Begin verification"), findsOneWidget);
    },
  );

  testWidgets(
    "allows selecting an unverified role without throwing dropdown assertion errors",
    (tester) async {
      final fakeRepo = FakeVerificationRepository();
      final controller = VerificationController(fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VerificationController>.value(
            value: controller,
            child: const VerificationRoleSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      controller.selectRole("Foster");
      await tester.pumpAndSettle();

      expect(find.text("What you need for Foster"), findsOneWidget);
    },
  );
}
