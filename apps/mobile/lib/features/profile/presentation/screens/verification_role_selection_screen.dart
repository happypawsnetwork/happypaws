import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:provider/provider.dart";

import "../../../../core/theme/app_colors.dart";
import "../controllers/verification_controller.dart";

class VerificationRoleSelectionScreen extends StatefulWidget {
  const VerificationRoleSelectionScreen({super.key});

  @override
  State<VerificationRoleSelectionScreen> createState() =>
      _VerificationRoleSelectionScreenState();
}

class _VerificationRoleSelectionScreenState
    extends State<VerificationRoleSelectionScreen> {
  static const Color verifiedBlue = Color(0xFF0064E0);

  final List<String> _availableRoles = const [
    "Adopter",
    "Foster",
    "Transporter",
    "Veterinarian",
    "Sponsor",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationController>().loadStatuses();
    });
  }

  String _getRoleRequirements(String role) {
    switch (role) {
      case "Adopter":
      case "Foster":
      case "Sponsor":
        return "• Valid government-issued ID (NIC or passport).\n\n"
            "* Optional: Proof of address if current residence differs from ID.";
      case "Transporter":
        return "• Valid driving license.\n\n"
            "• Vehicle insurance.\n\n"
            "* Optional: Proof of address if current residence differs from ID.";
      case "Veterinarian":
        return "• Valid government-issued ID (NIC, passport, or driving license).\n\n"
            "• VCSL Registration Certificate.\n\n"
            "* Optional: Proof of address if current residence differs from ID.";
      default:
        return "Select a role to see specific document requirements.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: const Text(
          "Select Role",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Consumer<VerificationController>(
        builder: (context, controller, child) {
          final selectedRole = controller.selectedRole;
          final statuses = {
            for (var s in controller.roleStatuses) s.role.toLowerCase(): s,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: verifiedBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      size: 56,
                      color: verifiedBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Identity verification",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Verify your account to build trust in the community, unlock adoption listings, and organize rescues.",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Modern full-width clean dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedRole != null
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedRole,
                      hint: Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Select Role",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      items: _availableRoles.map((role) {
                        final statusObj = statuses[role.toLowerCase()];
                        final isAlreadyVerified = statusObj?.isVerified == true;
                        final isPending = statusObj?.isPending == true;
                        final isDisabled = isAlreadyVerified || isPending;

                        return DropdownMenuItem<String>(
                          value: role,
                          enabled: !isDisabled,
                          child: Row(
                            children: [
                              Text(
                                role,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled
                                      ? Colors.grey.shade400
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (isAlreadyVerified) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Verified",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ] else if (isPending) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Pending",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectRole(val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Dynamic What you need card
                if (selectedRole != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "What you need for $selectedRole",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getRoleRequirements(selectedRole),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Begin Verification Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedRole != null
                        ? () {
                            context.push("/verification/upload");
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
                    child: const Text(
                      "Begin verification",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
