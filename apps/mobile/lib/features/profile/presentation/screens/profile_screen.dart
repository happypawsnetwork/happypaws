import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../controllers/profile_controller.dart';
import '../../domain/models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final ScrollController scrollController;
  final double topPadding;
  final VoidCallback? onNotificationsTap;

  const ProfileScreen({
    super.key,
    required this.scrollController,
    required this.topPadding,
    this.onNotificationsTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.userProfile;

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorMessage ?? 'Failed to load profile.',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadProfile(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final effectiveTopPadding = widget.topPadding > 0
            ? widget.topPadding
            : MediaQuery.paddingOf(context).top + 16;

        return Column(
          children: [
            SizedBox(height: effectiveTopPadding),
            _buildProfileCard(user),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.loadProfile(forceRefresh: true),
                child: ListView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildListTile(
                      icon: Icons.folder_shared_rounded,
                      title: 'My Content',
                      iconColor: Colors.orange,
                      onTap: () {
                        context.push('/profile/content');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.person_rounded,
                      title: 'My Profile',
                      iconColor: AppColors.accent,
                      onTap: () {
                        context.push('/profile/edit');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.verified_rounded,
                      title: 'Get Verified',
                      iconColor: const Color(0xFF0064E0),
                      onTap: () {
                        context.push('/verification');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.home_rounded,
                      title: 'Lifestyle Profile',
                      iconColor: Colors.green,
                      onTap: () {
                        context.push('/profile/lifestyle');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.assignment_rounded,
                      title: 'Adoption Applications',
                      iconColor: Colors.teal,
                      onTap: () {
                        context.push('/profile/applications');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.favorite_rounded,
                      title: 'My Rescues',
                      iconColor: Colors.pink,
                      onTap: () {
                        context.push('/profile/rescues');
                      },
                    ),
                    if (user.isFoster) ...[
                      const SizedBox(height: 8),
                      _buildListTile(
                        icon: Icons.pets_rounded,
                        title: 'Foster Care',
                        iconColor: Colors.green,
                        onTap: () {
                          context.push('/profile/foster-care');
                        },
                      ),
                    ],
                    if (user.isTransporter) ...[
                      const SizedBox(height: 8),
                      _buildListTile(
                        icon: Icons.local_shipping_rounded,
                        title: 'Animal Transports',
                        iconColor: Colors.indigo,
                        onTap: () {
                          context.push('/profile/transports');
                        },
                      ),
                    ],
                    if (user.isSponsor) ...[
                      const SizedBox(height: 8),
                      _buildListTile(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Sponsorships',
                        iconColor: Colors.amber,
                        onTap: () {
                          context.push('/profile/sponsorships');
                        },
                      ),
                    ],
                    if (user.isVeterinarian) ...[
                      const SizedBox(height: 8),
                      _buildListTile(
                        icon: Icons.medical_services_rounded,
                        title: 'Case Reviews',
                        iconColor: Colors.redAccent,
                        onTap: () {
                          context.push('/profile/case-reviews');
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildListTile(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      onTap: () {
                        if (widget.onNotificationsTap != null) {
                          widget.onNotificationsTap!();
                        } else {
                          context.push('/notifications');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildListTile(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: () async {
                        await controller.logout();
                        if (context.mounted) {
                          context.go('/onboarding');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCard(UserProfile user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: () {
                  context.push('/profile/edit');
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedBadge(size: 22),
                      ],
                    ],
                  ),
                  if (user.tagline != null && user.tagline!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${user.tagline}"',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.reputationPoints} Reputation',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: user.roles
                        .where((role) => role.isVisible)
                        .map<Widget>((role) => _buildRolePill(role.name))
                        .toList(),
                  ),
                  if (user.trustBadges.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: user.trustBadges
                          .map<Widget>((badge) => _buildTrustBadge(badge))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePill(String role) {
    IconData icon;
    Color color;

    switch (role.toLowerCase()) {
      case 'admin':
        icon = Icons.admin_panel_settings_rounded;
        color = Colors.deepPurple;
        break;
      case 'volunteer':
        icon = Icons.volunteer_activism_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.person_rounded;
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            role,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(String badge) {
    IconData icon;
    Color color;

    switch (badge.toLowerCase()) {
      case 'top responder':
        icon = Icons.local_fire_department_rounded;
        color = Colors.orange;
        break;
      case 'verified rescuer':
        icon = Icons.verified_user_rounded;
        color = Colors.blue;
        break;
      case '5+ adoptions':
        icon = Icons.pets_rounded;
        color = Colors.pink;
        break;
      default:
        icon = Icons.military_tech_rounded;
        color = Colors.amber;
        break;
    }

    return Tooltip(
      message: badge,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final c = textColor ?? const Color(0xFF334155);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF334155)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF334155)),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
