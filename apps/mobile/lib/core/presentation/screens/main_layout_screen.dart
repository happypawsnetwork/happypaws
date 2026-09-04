import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../../features/profile/presentation/controllers/profile_controller.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../features/community/presentation/screens/community_screen.dart';
import '../../../features/community/presentation/screens/nearby_rescue_map_screen.dart';
import '../../../features/messaging/presentation/controllers/chat_controller.dart';
import '../../../features/messaging/presentation/screens/chat_list_screen.dart';
import '../../theme/app_colors.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialIndex;

  const MainLayoutScreen({super.key, this.initialIndex = 0});

  /// Space below the status bar occupied by the floating header.
  /// Keep this aligned with [_MainLayoutScreenState._buildHeader] so feed
  /// content is not drawn under the logo row.
  static const double headerContentHeight =
      _headerTopInset + _headerActionSize + _headerBottomInset;

  static const double _headerTopInset = 8;
  static const double _headerBottomInset = 12;
  static const double _headerActionSize = 48;

  static double overlayHeaderHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + headerContentHeight;
  }

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;
  int _previousIndex = 0;
  bool _isHeaderVisible = true;
  double _lastOffset = 0;
  late final List<ScrollController> _scrollControllers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _isHeaderVisible = _currentIndex != 3 && _currentIndex != 4;
    _scrollControllers = List.generate(5, (_) => ScrollController());
    for (int i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].addListener(() => _handleScroll(i));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileController = context.read<ProfileController>();
        if (profileController.userProfile == null &&
            !profileController.isLoading) {
          profileController.loadProfile();
        }
        context.read<ChatController?>()?.fetchThreads();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleScroll(int index) {
    if (index != _currentIndex) return;

    final controller = _scrollControllers[index];
    if (!controller.hasClients) return;

    final offset = controller.offset;

    // Ignore overscroll to prevent iOS bounce flicker
    if (offset < 0 || offset > controller.position.maxScrollExtent) {
      return;
    }

    final threshold = MediaQuery.of(context).size.height * 0.25;
    final isScrollingDown = offset > _lastOffset;

    if (offset < threshold) {
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible = true);
      }
    } else {
      if (isScrollingDown && offset - _lastOffset > 2) {
        if (_isHeaderVisible) setState(() => _isHeaderVisible = false);
      } else if (!isScrollingDown && _lastOffset - offset > 2) {
        if (!_isHeaderVisible) setState(() => _isHeaderVisible = true);
      }
    }
    _lastOffset = offset;
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : const Color(0xFF94A3B8);

    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          selected: isSelected,
          button: true,
          child: InkWell(
            key: Key('nav_item_${label.toLowerCase()}'),
            onTap: () {
              setState(() {
                _currentIndex = index;
                _isHeaderVisible = true;
                if (_scrollControllers[index].hasClients) {
                  _lastOffset = _scrollControllers[index].offset;
                } else {
                  _lastOffset = 0;
                }
              });
              if (index == 2) {
                context.read<ChatController?>()?.fetchThreads();
              }
            },
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: index == 2
                    ? Consumer<ChatController>(
                        builder: (context, chatController, _) {
                          final unread = chatController.totalUnreadCount;
                          final iconWidget = Icon(
                            isSelected ? activeIcon : icon,
                            key: ValueKey('${isSelected}_$unread'),
                            color: color,
                            size: 26,
                          );

                          if (unread <= 0) {
                            return iconWidget;
                          }

                          return Badge.count(
                            count: unread,
                            backgroundColor: const Color(0xFF25D366),
                            textColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            child: iconWidget,
                          );
                        },
                      )
                    : Icon(
                        isSelected ? activeIcon : icon,
                        key: ValueKey(isSelected),
                        color: color,
                        size: 26,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = _currentIndex == 3;
    const double avatarSize = 40.0;

    return Expanded(
      child: Tooltip(
        message: 'Profile',
        child: Semantics(
          label: 'Profile',
          selected: isSelected,
          button: true,
          child: InkWell(
            key: const Key('nav_item_profile'),
            onTap: () {
              setState(() {
                _currentIndex = 3;
                _isHeaderVisible = false;
                if (_scrollControllers[3].hasClients) {
                  _lastOffset = _scrollControllers[3].offset;
                } else {
                  _lastOffset = 0;
                }
              });
            },
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Consumer<ProfileController>(
              builder: (context, profileController, _) {
                final profile = profileController.userProfile;
                final avatarUrl = profile?.avatarUrl;
                final name = profile?.name ?? '';
                final initial = name.trim().isNotEmpty
                    ? name.trim()[0].toUpperCase()
                    : '?';

                Widget avatarWidget;
                if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
                  avatarWidget = Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.accent.withValues(alpha: 0.24),
                        width: isSelected ? 2.5 : 2.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackAvatar(
                              initial,
                              isSelected,
                              avatarSize,
                            ),
                      ),
                    ),
                  );
                } else {
                  avatarWidget = _buildFallbackAvatar(
                    initial,
                    isSelected,
                    avatarSize,
                  );
                }

                return Center(child: avatarWidget);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(
    String initial,
    bool isSelected, [
    double size = 40.0,
  ]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.accent.withValues(alpha: 0.24),
          width: isSelected ? 2.5 : 2.0,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top:
            MediaQuery.paddingOf(context).top +
            MainLayoutScreen._headerTopInset,
        bottom: MainLayoutScreen._headerBottomInset,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        height: MainLayoutScreen._headerActionSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: MainLayoutScreen._headerActionSize,
                minHeight: MainLayoutScreen._headerActionSize,
              ),
              icon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1E293B),
                size: 28,
              ),
              onPressed: () {
                context.push('/search');
              },
            ),
            SvgPicture.asset('assets/svg/ic_brand_horizontal.svg', height: 28),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: MainLayoutScreen._headerActionSize,
                minHeight: MainLayoutScreen._headerActionSize,
              ),
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1E293B),
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  _previousIndex = _currentIndex;
                  _currentIndex = 4;
                  _isHeaderVisible = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const double barHeight = 52.0;
    const double buttonDiameter = 52.0;
    const double buttonProtrusion = 26.0;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: barHeight + buttonProtrusion + bottomSafeArea,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomSafeArea,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.group_outlined,
                        activeIcon: Icons.group,
                        label: 'Community',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.location_on_outlined,
                        activeIcon: Icons.location_on,
                        label: 'Nearby',
                      ),
                      const SizedBox(width: 56),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum,
                        label: 'Chats',
                      ),
                      _buildProfileNavItem(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: barHeight + bottomSafeArea - (buttonDiameter / 2),
            child: Semantics(
              button: true,
              label: 'Create new post or report',
              child: GestureDetector(
                onTap: () {
                  context.push('/community/create/pick-type');
                },
                child: Container(
                  width: buttonDiameter,
                  height: buttonDiameter,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MainLayoutScreen.overlayHeaderHeight(context);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = _previousIndex;
          _isHeaderVisible = _currentIndex != 3 && _currentIndex != 4;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                CommunityScreen(
                  scrollController: _scrollControllers[0],
                  topPadding: topPadding,
                  isNearby: false,
                ),
                NearbyRescueMapScreen(topPadding: topPadding),
                ChatListScreen(
                  scrollController: _scrollControllers[2],
                  topPadding: topPadding,
                ),
                ProfileScreen(
                  scrollController: _scrollControllers[3],
                  topPadding: 0,
                  onNotificationsTap: () {
                    setState(() {
                      _previousIndex = 3;
                      _currentIndex = 4;
                      _isHeaderVisible = false;
                    });
                  },
                ),
                NotificationsScreen(
                  scrollController: _scrollControllers[4],
                  onBack: () {
                    setState(() {
                      _currentIndex = _previousIndex;
                      _isHeaderVisible =
                          _currentIndex != 3 && _currentIndex != 4;
                    });
                  },
                ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // Hide header if on Profile (index 3), Notifications (index 4), or if scrolled up
              top:
                  (_isHeaderVisible && _currentIndex != 3 && _currentIndex != 4)
                  ? 0
                  : -(topPadding + 20),
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}
