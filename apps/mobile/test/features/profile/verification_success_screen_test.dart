import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";
import "package:mobile/features/profile/domain/models/role_verification_status.dart";
import "package:mobile/features/profile/domain/repositories/i_verification_repository.dart";
import "package:mobile/features/profile/presentation/controllers/verification_controller.dart";
import "package:mobile/features/profile/presentation/screens/verification_success_screen.dart";

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
    "renders VerificationSuccessScreen with Back to Profile button and no back icon",
    (tester) async {
      final fakeRepo = FakeVerificationRepository();
      final controller = VerificationController(fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VerificationController>.value(
            value: controller,
            child: const VerificationSuccessScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Verification Submitted"), findsOneWidget);
      expect(find.text("Back to Profile"), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    },
  );
}
