import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/i_post_repository.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_media_carousel.dart';
import '../widgets/post_type_pill.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Post? initialPost;

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Post?> _postFuture;
  bool? _isLiked;
  int? _likeCount;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _postFuture = Future.value(widget.initialPost);
      _isLiked = widget.initialPost!.isLikedByCurrentUser;
      _likeCount = widget.initialPost!.likeCount;
    } else {
      _postFuture = context.read<IPostRepository>().getPostById(widget.postId);
    }
  }

  Future<void> _handleToggleLike(Post post) async {
    final bool currentlyLiked = _isLiked ?? post.isLikedByCurrentUser;
    final int currentCount = _likeCount ?? post.likeCount;
    final bool newLiked = !currentlyLiked;
    final int newCount = currentlyLiked ? currentCount - 1 : currentCount + 1;

    setState(() {
      _isLiked = newLiked;
      _likeCount = newCount < 0 ? 0 : newCount;
    });

    try {
      final result = await context.read<IPostRepository>().toggleLike(post.id);
      if (mounted) {
        setState(() {
          _isLiked = result.isLiked;
          _likeCount = result.likeCount;
        });
        context.read<CommunityController>().updatePostLikeState(
          post.id,
          result.isLiked,
          result.likeCount,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = currentlyLiked;
          _likeCount = currentCount;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
      }
    }
  }

  Widget _buildUrgencySection(Post post) {
    if (post.type != PostType.rescueAlert) return const SizedBox.shrink();

    Color bg = UrgencyColors.unknownBg;
    Color border = UrgencyColors.unknownBorder;
    Color text = UrgencyColors.unknownText;
    String label = 'Urgency not assessed';

    if (post.urgencyLevel == 'Critical') {
      bg = UrgencyColors.criticalBg;
      border = UrgencyColors.criticalBorder;
      text = UrgencyColors.criticalText;
      label = 'Critical urgency';
    } else if (post.urgencyLevel == 'High') {
      bg = UrgencyColors.highBg;
      border = UrgencyColors.highBorder;
      text = UrgencyColors.highText;
      label = 'High urgency';
    } else if (post.urgencyLevel == 'Medium') {
      bg = UrgencyColors.mediumBg;
      border = UrgencyColors.mediumBorder;
      text = UrgencyColors.mediumText;
      label = 'Medium urgency';
    } else if (post.urgencyLevel == 'Low') {
      bg = UrgencyColors.lowBg;
      border = UrgencyColors.lowBorder;
      text = UrgencyColors.lowText;
      label = 'Low urgency';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'AI assessed',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.aiTriageReason ?? 'No reason available from AI assessment',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontStyle: post.aiTriageReason == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildActionBanner(Post post) {
    if (post.type == PostType.rescueAlert) {
      if (post.status == PostStatus.active) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), // amber-50
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.applicantCount ?? 0} applicants',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                ),
                child: const Text('Apply to rescue'),
              ),
            ],
          ),
        );
      } else if (post.status == PostStatus.assigned ||
          post.status == PostStatus.fostered) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5), // emerald-50
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)), // emerald-200
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                'This rescue has been assigned.',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF065F46),
                ),
              ),
            ],
          ),
        );
      }
    } else if (post.type == PostType.fosterUpdate &&
        post.parentPostTitle != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Linked rescue: ${post.parentPostTitle}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('View rescue'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVetDetails(Post post) {
    if (post.type != PostType.vetRequest || post.vetDetails == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Vet details',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.vetDetails!.clinicName != null) ...[
            Text(
              'Clinic: ${post.vetDetails!.clinicName}',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (post.vetDetails!.appointmentDate != null)
            Text(
              'Appointment: ${post.vetDetails!.appointmentDate}',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSponsorDetails(Post post) {
    if (post.type != PostType.sponsorshipRequest ||
        post.sponsorshipDetails == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Funding Goal',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'LKR ${post.sponsorshipDetails!.estimatedAmountLkr?.toStringAsFixed(2) ?? 'Unknown'}',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Post post) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.media.isNotEmpty)
            PostMediaCarousel(media: post.media)
          else if (post.firstPhotoUrl != null)
            Image.network(
              post.firstPhotoUrl!,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 280,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostTypePill(type: post.type),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildUrgencySection(post),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          context.push('/profile/public/${post.authorId}');
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage:
                                  (post.authorAvatarUrl != null &&
                                      post.authorAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(post.authorAvatarUrl!)
                                  : null,
                              child:
                                  (post.authorAvatarUrl == null ||
                                      post.authorAvatarUrl!.isEmpty)
                                  ? Text(
                                      post.authorDisplayName.isNotEmpty
                                          ? post.authorDisplayName[0]
                                                .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorDisplayName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (post.authorTagline != null &&
                                      post.authorTagline!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      post.authorTagline!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildActionBanner(post),
                const SizedBox(height: 24),

                // Location tap
                if ((post.locationLabel != null &&
                        post.locationLabel!.isNotEmpty) ||
                    (post.latitude != null && post.longitude != null))
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final lat = post.latitude;
                      final lng = post.longitude;
                      final label = post.locationLabel;

                      Uri? geoUri;
                      Uri? webUri;

                      if (lat != null && lng != null) {
                        final encodedLabel = Uri.encodeComponent(
                          label ?? 'Animal Location',
                        );
                        geoUri = Uri.parse(
                          'geo:$lat,$lng?q=$lat,$lng($encodedLabel)',
                        );
                        webUri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                        );
                      } else if (label != null && label.isNotEmpty) {
                        final encodedQuery = Uri.encodeComponent(label);
                        geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
                        webUri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
                        );
                      }

                      if (geoUri != null) {
                        try {
                          if (await canLaunchUrl(geoUri)) {
                            await launchUrl(geoUri);
                            return;
                          }
                        } catch (_) {}
                      }

                      if (webUri != null) {
                        try {
                          if (await canLaunchUrl(webUri)) {
                            await launchUrl(
                              webUri,
                              mode: LaunchMode.externalApplication,
                            );
                            return;
                          }
                        } catch (_) {}
                        await launchUrl(
                          webUri,
                          mode: LaunchMode.platformDefault,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (post.locationLabel != null &&
                                    post.locationLabel!.isNotEmpty)
                                ? post.locationLabel!
                                : '${post.latitude!.toStringAsFixed(4)}, ${post.longitude!.toStringAsFixed(4)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (post.animalSpecies != null || post.animalName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [
                              if (post.animalName != null) post.animalName,
                              if (post.animalSpecies != null)
                                post.animalSpecies,
                            ].join(' • '),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Text(
                  post.body,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                _buildAdoptionLifestyleDetails(post),
                _buildVetDetails(post),
                _buildSponsorDetails(post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdoptionLifestyleDetails(Post post) {
    if (post.type != PostType.adoptionListing || post.expectations == null) {
      return const SizedBox.shrink();
    }
    final exp = post.expectations!;

    String homeSizeLabel(String size) {
      switch (size) {
        case 'Apartment':
          return 'Apartment / Flat';
        case 'SingleHouse':
          return 'Single house';
        case 'Estate':
          return 'Estate / Acreage';
        default:
          return size;
      }
    }

    String tempoLabel(String tempo) {
      switch (tempo) {
        case 'RelaxedAndCalm':
          return 'Relaxed & calm';
        case 'ModeratelyActive':
          return 'Moderately active';
        case 'HighEnergy':
          return 'High energy';
        default:
          return tempo;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.home_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ideal home requirements',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (exp.homeSize != null) ...[
            _buildLifestyleRow(
              Icons.apartment_rounded,
              'Minimum home size',
              homeSizeLabel(exp.homeSize!),
            ),
            const SizedBox(height: 8),
          ],
          _buildLifestyleRow(
            Icons.grass_rounded,
            'Enclosed yard',
            exp.requiresEnclosedYard ? 'Required' : 'Not required',
          ),
          const SizedBox(height: 8),
          _buildLifestyleRow(
            Icons.family_restroom_rounded,
            'Children under 12',
            exp.goodWithChildren
                ? 'Good with children'
                : 'Adults only preferred',
          ),
          if (exp.activityTempo != null) ...[
            const SizedBox(height: 8),
            _buildLifestyleRow(
              Icons.directions_run_rounded,
              'Activity tempo',
              tempoLabel(exp.activityTempo!),
            ),
          ],
          if (exp.goodWithPets.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLifestyleRow(
              Icons.pets_rounded,
              'Compatible pets',
              exp.goodWithPets.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifestyleRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: FutureBuilder<Post?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load post.'));
          }

          return _buildContent(snapshot.data!);
        },
      ),
      floatingActionButton: FutureBuilder<Post?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final post = snapshot.data!;
          final isLiked = _isLiked ?? post.isLikedByCurrentUser;
          final count = _likeCount ?? post.likeCount;
          return FloatingActionButton.extended(
            onPressed: () => _handleToggleLike(post),
            backgroundColor: AppColors.surface,
            elevation: 4,
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.heartPink : AppColors.textSecondary,
            ),
            label: Text(
              '$count',
              style: GoogleFonts.outfit(
                color: isLiked ? AppColors.heartPink : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
