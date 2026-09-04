import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/post.dart';
import 'post_type_pill.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/community_controller.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Widget _buildUrgencyBadge() {
    Color bg = UrgencyColors.unknownBg;
    Color border = UrgencyColors.unknownBorder;
    Color text = UrgencyColors.unknownText;
    String label = '?';

    if (post.urgencyLevel == 'Critical') {
      bg = UrgencyColors.criticalBg;
      border = UrgencyColors.criticalBorder;
      text = UrgencyColors.criticalText;
      label = 'Critical';
    } else if (post.urgencyLevel == 'High') {
      bg = UrgencyColors.highBg;
      border = UrgencyColors.highBorder;
      text = UrgencyColors.highText;
      label = 'High';
    } else if (post.urgencyLevel == 'Medium') {
      bg = UrgencyColors.mediumBg;
      border = UrgencyColors.mediumBorder;
      text = UrgencyColors.mediumText;
      label = 'Medium';
    } else if (post.urgencyLevel == 'Low') {
      bg = UrgencyColors.lowBg;
      border = UrgencyColors.lowBorder;
      text = UrgencyColors.lowText;
      label = 'Low';
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAnimalInfo() {
    if (post.animalSpecies == null && post.animalName == null) {
      return const SizedBox.shrink();
    }

    final List<String> parts = [];
    if (post.animalName != null && post.animalName!.isNotEmpty) {
      parts.add(post.animalName!);
    }
    if (post.animalSpecies != null && post.animalSpecies!.isNotEmpty) {
      parts.add(post.animalSpecies!);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.pets, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            parts.join(' • '),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final String initial = post.authorDisplayName.isNotEmpty
        ? post.authorDisplayName[0].toUpperCase()
        : '?';
    if (post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          post.authorAvatarUrl!,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial),
        ),
      );
    }
    return _buildFallbackAvatar(initial);
  }

  Widget _buildFallbackAvatar(String initial) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.firstPhotoUrl != null && post.firstPhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: post.firstPhotoUrl!.startsWith('http')
                    ? Image.network(
                        post.firstPhotoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.splashBackground,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.splashBackground,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(post.firstPhotoUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.splashBackground,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PostTypePill(type: post.type),
                    if (post.isRecommended)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (post.type == PostType.rescueAlert &&
                        post.urgencyLevel != null)
                      _buildUrgencyBadge(),
                    const Spacer(),
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildAnimalInfo(),
                if (post.locationLabel != null &&
                    post.locationLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.locationLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 8),
                    Text(
                      post.authorDisplayName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        context.read<CommunityController>().toggleLike(post.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              post.isLikedByCurrentUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: post.isLikedByCurrentUser
                                  ? AppColors.heartPink
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: post.isLikedByCurrentUser
                                    ? AppColors.heartPink
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
