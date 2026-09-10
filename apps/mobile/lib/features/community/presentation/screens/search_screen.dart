import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/search_feed_controller.dart';
import '../widgets/post_card.dart';
import '../widgets/search_filter_modal.dart';

/// Screen allowing adopters to search and filter listed animals and community posts.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SearchFeedController>();
      _textController.text = controller.query;
      // If there are already filters or query, search immediately
      if (controller.query.isNotEmpty || controller.hasActiveFilters) {
        controller.performSearch();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<SearchFeedController>().loadMore();
    }
  }

  void _openFilterModal() {
    final controller = context.read<SearchFeedController>();
    SearchFilterModal.show(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Search',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<SearchFeedController>(
            builder: (context, controller, _) {
              final activeCount = controller.activeFilterCount;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  tooltip: 'Open filters',
                  icon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onPressed: _openFilterModal,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SearchFeedController>(
        builder: (context, controller, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    return TextField(
                      controller: _textController,
                      onChanged: (text) => controller.onQueryChanged(text),
                      onSubmitted: (text) =>
                          controller.onQueryChanged(text, immediate: true),
                      textInputAction: TextInputAction.search,
                      autofocus:
                          controller.query.isEmpty &&
                          !controller.hasActiveFilters,
                      decoration: InputDecoration(
                        hintText: 'Search animals, breeds, places...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _textController.clear();
                                  controller.onQueryChanged(
                                    '',
                                    immediate: true,
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Quick filter chips row
              _buildQuickFilterBar(controller),

              // Active filter tags row
              if (controller.hasActiveFilters)
                _buildActiveFilterTags(controller),

              // Divider
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

              // Results or empty state
              Expanded(child: _buildBody(controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterBar(SearchFeedController controller) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          // Filter modal launcher button
          ActionChip(
            avatar: const Icon(Icons.tune, size: 16, color: AppColors.primary),
            label: Text(
              controller.activeFilterCount > 0
                  ? 'Filters (${controller.activeFilterCount})'
                  : 'Filters',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: _openFilterModal,
          ),
          const SizedBox(width: 8),

          // Species: Dog
          _buildQuickChip(
            label: '🐕 Dogs',
            isSelected: controller.species?.toLowerCase() == 'dog',
            onTap: () {
              controller.setSpecies(
                controller.species?.toLowerCase() == 'dog' ? null : 'Dog',
              );
            },
          ),
          const SizedBox(width: 8),

          // Species: Cat
          _buildQuickChip(
            label: '🐈 Cats',
            isSelected: controller.species?.toLowerCase() == 'cat',
            onTap: () {
              controller.setSpecies(
                controller.species?.toLowerCase() == 'cat' ? null : 'Cat',
              );
            },
          ),
          const SizedBox(width: 8),

          // Type: Find Home
          _buildQuickChip(
            label: '🏠 Find Home',
            isSelected: controller.type == 'AdoptionListing',
            onTap: () {
              controller.setType(
                controller.type == 'AdoptionListing' ? null : 'AdoptionListing',
              );
            },
          ),
          const SizedBox(width: 8),

          // Type: Rescue
          _buildQuickChip(
            label: '🚨 Rescue',
            isSelected: controller.type == 'RescueAlert',
            onTap: () {
              controller.setType(
                controller.type == 'RescueAlert' ? null : 'RescueAlert',
              );
            },
          ),
          const SizedBox(width: 8),

          // Urgency: Critical / High
          _buildQuickChip(
            label: '🔴 Critical',
            isSelected: controller.urgency == 'Critical',
            onTap: () {
              controller.setUrgency(
                controller.urgency == 'Critical' ? null : 'Critical',
              );
            },
          ),
          const SizedBox(width: 8),

          _buildQuickChip(
            label: '🟠 High',
            isSelected: controller.urgency == 'High',
            onTap: () {
              controller.setUrgency(
                controller.urgency == 'High' ? null : 'High',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      backgroundColor: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }

  Widget _buildActiveFilterTags(SearchFeedController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (controller.species != null && controller.species!.isNotEmpty)
            _buildActiveTag(
              'Species: ${controller.species}',
              () => controller.removeFilter('species'),
            ),
          if (controller.location != null && controller.location!.isNotEmpty)
            _buildActiveTag(
              'Location: ${controller.location}',
              () => controller.removeFilter('location'),
            ),
          if (controller.urgency != null && controller.urgency!.isNotEmpty)
            _buildActiveTag(
              'Urgency: ${controller.urgency}',
              () => controller.removeFilter('urgency'),
            ),
          if (controller.type != null && controller.type!.isNotEmpty)
            _buildActiveTag(
              controller.type == 'AdoptionListing'
                  ? 'Find Home'
                  : controller.type == 'RescueAlert'
                  ? 'Rescue'
                  : controller.type!,
              () => controller.removeFilter('type'),
            ),
          if (controller.onlyRecommended)
            _buildActiveTag(
              'Recommended only',
              () => controller.removeFilter('recommended'),
            ),
          InkWell(
            onTap: () => controller.clearAllFilters(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Clear all',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchFeedController controller) {
    if (controller.state == SearchFeedState.loading &&
        controller.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Searching listed animals...',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.state == SearchFeedState.error &&
        controller.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage ?? 'Failed to complete search.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.performSearch(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.state == SearchFeedState.idle) {
      return _buildIdleState(controller);
    }

    final displayed = controller.displayedResults;

    if (displayed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No animals found',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No listed animals match your current search and filter criteria. Try adjusting your query or resetting filters.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (controller.hasActiveFilters) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => controller.clearAllFilters(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Clear all filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: displayed.length + (controller.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == displayed.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return PostCard(post: displayed[index]);
      },
    );
  }

  Widget _buildIdleState(SearchFeedController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore listed animals',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find animals to adopt or foster by species, location, and urgency, independent of lifestyle profile suggestions.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Suggested search prompts
          _buildSuggestionTile(
            icon: Icons.pets,
            title: 'Dogs looking for a home',
            subtitle: 'Adoption listings for friendly dogs',
            onTap: () {
              controller.applyFilters(species: 'Dog', type: 'AdoptionListing');
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestionTile(
            icon: Icons.favorite_border,
            title: 'Cats looking for a home',
            subtitle: 'Adoption listings for cuddly cats',
            onTap: () {
              controller.applyFilters(species: 'Cat', type: 'AdoptionListing');
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestionTile(
            icon: Icons.emergency,
            title: 'Urgent rescue alerts',
            subtitle: 'Critical and high urgency animals needing rescue',
            onTap: () {
              controller.applyFilters(type: 'RescueAlert', urgency: 'High');
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestionTile(
            icon: Icons.explore_outlined,
            title: 'Browse all animal posts',
            subtitle: 'View all active adoption listings and rescues',
            onTap: () {
              controller.performSearch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
