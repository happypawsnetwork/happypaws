import "dart:io";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

import "../../../../core/theme/app_colors.dart";
import "../controllers/verification_controller.dart";

class DocumentRequirementItem {
  final String key;
  final String title;
  final String description;
  final bool isRequired;
  final IconData icon;
  final String? testSamplePath;

  const DocumentRequirementItem({
    required this.key,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.icon,
    this.testSamplePath,
  });
}

class VerificationUploadScreen extends StatefulWidget {
  const VerificationUploadScreen({super.key});

  @override
  State<VerificationUploadScreen> createState() =>
      _VerificationUploadScreenState();
}

class _VerificationUploadScreenState extends State<VerificationUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  List<DocumentRequirementItem> _getRequirementsForRole(String role) {
    switch (role) {
      case "Transporter":
        return const [
          DocumentRequirementItem(
            key: "DrivingLicense",
            title: "Driving License",
            description: "Front copy of your valid driving license.",
            isRequired: true,
            icon: Icons.drive_eta_rounded,
            testSamplePath: "test-data/kyc/placeholder_driving_license.jpg",
          ),
          DocumentRequirementItem(
            key: "VehicleInsurance",
            title: "Vehicle Insurance",
            description:
                "Valid commercial or personal vehicle insurance policy.",
            isRequired: true,
            icon: Icons.security_rounded,
            testSamplePath: "test-data/kyc/placeholder_vehicle_insurance.jpg",
          ),
          DocumentRequirementItem(
            key: "ProofOfAddress",
            title: "Proof of Address",
            description: "Utility bill or bank statement if residing at a different address.",
            isRequired: false,
            icon: Icons.home_work_rounded,
          ),
        ];
      case "Veterinarian":
        return const [
          DocumentRequirementItem(
            key: "GovernmentId",
            title: "Government Identity Document",
            description: "National ID (NIC), Passport, or Driving License.",
            isRequired: true,
            icon: Icons.badge_outlined,
            testSamplePath: "test-data/kyc/placeholder_nic.jpg",
          ),
          DocumentRequirementItem(
            key: "VcslCertificate",
            title: "VCSL Registration Certificate",
            description:
                "Veterinary Council of Sri Lanka annual registration document.",
            isRequired: true,
            icon: Icons.verified_user_rounded,
            testSamplePath: "test-data/kyc/placeholder_vcsl_certificate.jpg",
          ),
          DocumentRequirementItem(
            key: "ProofOfAddress",
            title: "Proof of Address",
            description: "Utility bill or bank statement if residing at a different address.",
            isRequired: false,
            icon: Icons.home_work_rounded,
          ),
        ];
      case "Adopter":
      case "Foster":
      case "Sponsor":
      default:
        return const [
          DocumentRequirementItem(
            key: "GovernmentId",
            title: "Government Identity Document",
            description: "National ID card (NIC) or Passport.",
            isRequired: true,
            icon: Icons.badge_outlined,
            testSamplePath: "test-data/kyc/placeholder_nic.jpg",
          ),
          DocumentRequirementItem(
            key: "ProofOfAddress",
            title: "Proof of Address",
            description: "Utility bill or bank statement if residing at a different address.",
            isRequired: false,
            icon: Icons.home_work_rounded,
          ),
        ];
    }
  }

  void _showPickerBottomSheet(
    BuildContext context,
    DocumentRequirementItem item,
  ) {
    final controller = context.read<VerificationController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload ${item.title}",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Select a source to upload your verification document",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  "Take Photo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Use your camera to capture document"),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (picked != null) {
                    controller.setDocumentFile(item.key, File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Select image from photo library"),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    controller.setDocumentFile(item.key, File(picked.path));
                  }
                },
              ),
              if (item.testSamplePath != null &&
                  File(item.testSamplePath!).existsSync()) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  title: const Text(
                    "Use Test Sample KYC",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Load local test placeholder asset"),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.setDocumentFile(
                      item.key,
                      File(item.testSamplePath!),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VerificationController>(
      builder: (context, controller, child) {
        final role = controller.selectedRole ?? "Adopter";
        final requirements = _getRequirementsForRole(role);
        final canSubmit = controller.canSubmit();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "$role Verification",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Documents",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Please upload clear, legible copies of your documents. All documents are stored securely with end-to-end encryption.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ...requirements.map((item) {
                      final selectedFile = controller.selectedFiles[item.key];
                      return _buildDocumentCard(context, item, selectedFile);
                    }),
                  ],
                ),
              ),

              // Bottom Sticky Submit Action
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canSubmit && !controller.isSubmitting
                            ? () async {
                                final success = await controller
                                    .submitVerification();
                                if (success && context.mounted) {
                                  context.go("/verification/success");
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.35,
                          ),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Submit Documents",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    DocumentRequirementItem item,
    File? selectedFile,
  ) {
    final controller = context.read<VerificationController>();
    final isUploaded = selectedFile != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUploaded
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isUploaded ? AppColors.primary : Colors.grey.shade600)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isUploaded
                        ? AppColors.primary
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isRequired
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isRequired ? "Required" : "Optional",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.isRequired
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload Box or Thumbnail Preview
            if (isUploaded) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  image: DecorationImage(
                    image: FileImage(selectedFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPickerBottomSheet(context, item),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Replace"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => controller.removeDocumentFile(item.key),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Remove"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: () => _showPickerBottomSheet(context, item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 28,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap to upload file",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          "Supports JPG, PNG",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
