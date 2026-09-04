import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../../../../core/theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  final ScrollController scrollController;
  final double topPadding;
  final bool isNearby;

  const CommunityScreen({
    super.key,
    required this.scrollController,
    required this.topPadding,
    this.isNearby = false,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _locationPermissionGranted = false;

  final List<String> _filters = [
    "All",
    "🚨 Rescue",
    "🐾 Update",
    "🏠 Find Home",
    "✨ Highlight",
    "🚐 Transport",
    "💊 Treatment",
    "💛 Sponsor",
  ];

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNearby) {
        // Initially don't load until location is allowed
      } else {
        context.read<CommunityController>().loadFeed();
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 300) {
      final controller = context.read<CommunityController>();
      if (widget.isNearby) {
        if (_locationPermissionGranted) {
          controller.loadMoreNearby();
        }
      } else {
        controller.loadMore();
      }
    }
  }

  void _requestLocation() {
    setState(() {
      _locationPermissionGranted = true;
    });
    context.read<CommunityController>().loadNearbyFeed(
      6.9271,
      79.8612,
    ); // Colombo
  }

  String? _mapFilterToType(String filter) {
    if (filter == "All") return null;
    if (filter.contains("Rescue")) return "RescueAlert";
    if (filter.contains("Update")) return "FosterUpdate";
    if (filter.contains("Find Home")) return "AdoptionListing";
    if (filter.contains("Highlight")) return "Highlight";
    if (filter.contains("Transport")) return "TransportRequest";
    if (filter.contains("Treatment")) return "VetRequest";
    if (filter.contains("Sponsor")) return "SponsorshipRequest";
    return null;
  }

  String _mapTypeToFilter(String? type) {
    if (type == "RescueAlert") return "🚨 Rescue";
    if (type == "FosterUpdate") return "🐾 Update";
    if (type == "AdoptionListing") return "🏠 Find Home";
    if (type == "Highlight") return "✨ Highlight";
    if (type == "TransportRequest") return "🚐 Transport";
    if (type == "VetRequest") return "💊 Treatment";
    if (type == "SponsorshipRequest") return "💛 Sponsor";
    return "All";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityController>(
      builder: (context, controller, child) {
        final posts = widget.isNearby
            ? controller.nearbyPosts
            : controller.posts;
        final hasMore = widget.isNearby
            ? controller.nearbyHasMore
            : controller.hasMore;
        final currentFilter = _mapTypeToFilter(controller.selectedType);

        if (widget.isNearby && !_locationPermissionGranted) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Location access needed',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'To show posts within 10 km',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _requestLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Allow Location',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.isNearby
              ? controller.loadNearbyFeed(6.9271, 79.8612, isRefresh: true)
              : controller.loadFeed(isRefresh: true),
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(padding: EdgeInsets.only(top: widget.topPadding)),

              if (widget.isNearby)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Posts within 10 km',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == currentFilter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            controller.setTypeFilter(
                              _mapFilterToType(filter),
                              isNearby: widget.isNearby,
                            );
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filter,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (controller.state == CommunityState.loading && posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (controller.state == CommunityState.error &&
                  posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      controller.errorMessage ?? 'An error occurred',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else if (posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No posts found.',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == posts.length) {
                        if (hasMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 32.0,
                            horizontal: 24.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 1,
                                    width: 36,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Icon(
                                      Icons.pets_rounded,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    width: 36,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "You've seen all the furry friends for now! 🐾",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            context.push('/community/post/${posts[index].id}');
                          },
                          child: PostCard(post: posts[index]),
                        ),
                      );
                    }, childCount: posts.length + 1),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
