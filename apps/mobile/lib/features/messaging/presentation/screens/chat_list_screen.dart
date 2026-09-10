import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/chat_controller.dart';
import '../../data/models/chat_thread.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  final ScrollController scrollController;
  final double topPadding;

  const ChatListScreen({
    super.key,
    required this.scrollController,
    required this.topPadding,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteThread(ChatThread thread) async {
    final myProfile = context.read<ProfileController>().userProfile;
    final isSelf =
        thread.isSelf ||
        (myProfile != null && thread.otherParticipant?.userId == myProfile.id);
    final rawName =
        '${thread.otherParticipant?.firstName ?? ''} ${thread.otherParticipant?.lastName ?? ''}'
            .trim();
    final otherName = isSelf
        ? (rawName.isNotEmpty ? '$rawName (Me)' : 'Saved Messages')
        : rawName;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSelf ? 'Clear saved messages?' : 'Delete conversation?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          isSelf
              ? 'This will permanently remove your saved notes and messages for you.'
              : 'This will permanently remove the conversation with $otherName for you. The other participant will not be affected.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              isSelf ? 'Clear' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ChatController>().deleteThread(
        thread.id,
      );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSelf ? 'Saved messages cleared' : 'Conversation deleted',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, child) {
        final myProfile = context.watch<ProfileController>().userProfile;
        final filteredThreads = controller.threads.where((t) {
          if (_searchQuery.isEmpty) return true;
          final isSelf =
              t.isSelf ||
              (myProfile != null && t.otherParticipant?.userId == myProfile.id);
          final rawName =
              '${t.otherParticipant?.firstName ?? ''} ${t.otherParticipant?.lastName ?? ''}'
                  .toLowerCase();
          final displayName = isSelf ? '$rawName (me)' : rawName;
          final lastContent = t.lastMessage?.content.toLowerCase() ?? '';
          return displayName.contains(_searchQuery) ||
              lastContent.contains(_searchQuery) ||
              (isSelf && 'saved messages'.contains(_searchQuery));
        }).toList();

        final totalCount =
            2 +
            (controller.isLoading && controller.threads.isEmpty
                ? 1
                : (filteredThreads.isEmpty ? 1 : filteredThreads.length));

        return RefreshIndicator(
          color: AppColors.primary,
          edgeOffset: widget.topPadding,
          onRefresh: () async {
            await controller.fetchThreads();
          },
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: widget.topPadding + 8, bottom: 96),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                // 1. Header
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Text(
                      'Messages',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }

                // 2. Search Input
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search chats...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // 3. Loading state
                if (controller.isLoading && controller.threads.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                // 4. Empty state
                if (filteredThreads.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No messages yet'
                                : 'No matching chats found',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Start a conversation by visiting any user profile'
                                : 'Try searching for a different name or keyword',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 5. Conversation tile
                final threadIndex = index - 2;
                final thread = filteredThreads[threadIndex];
                final other = thread.otherParticipant;
                final hasAvatar =
                    other?.avatarUrl != null && other!.avatarUrl!.isNotEmpty;
                final initials = other != null && other.firstName.isNotEmpty
                    ? other.firstName[0].toUpperCase()
                    : '?';
                final isSelf =
                    thread.isSelf ||
                    (myProfile != null && other?.userId == myProfile.id);
                final rawName =
                    '${other?.firstName ?? ''} ${other?.lastName ?? ''}'.trim();
                final displayName = isSelf
                    ? (rawName.isNotEmpty ? '$rawName (Me)' : 'Saved Messages')
                    : rawName;

                return Dismissible(
                  key: ValueKey('thread_${thread.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.red.shade500,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    await _confirmDeleteThread(thread);
                    return false; // deleteThread in confirm will update state
                  },
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (other != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatThreadScreen(
                                  threadId: thread.id,
                                  targetUserId: other.userId,
                                  targetName: displayName,
                                  targetAvatarUrl: other.avatarUrl,
                                  isSelf: isSelf,
                                  isTargetVerified: other.isVerified,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: hasAvatar
                                    ? NetworkImage(other.avatarUrl!)
                                    : null,
                                child: !hasAvatar
                                    ? Text(
                                        initials,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  displayName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        (thread.unreadCount >
                                                                0 &&
                                                            !isSelf)
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (other?.isVerified ==
                                                  true) ...[
                                                const SizedBox(width: 4),
                                                const VerifiedBadge(size: 15),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (thread.lastMessage != null)
                                          Text(
                                            '${thread.updatedAt.toLocal().hour.toString().padLeft(2, '0')}:${thread.updatedAt.toLocal().minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  (thread.unreadCount > 0 &&
                                                      !isSelf)
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color:
                                                  (thread.unreadCount > 0 &&
                                                      !isSelf)
                                                  ? const Color(0xFF25D366)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (thread.lastMessage != null &&
                                                  !isSelf &&
                                                  thread
                                                          .lastMessage!
                                                          .senderId !=
                                                      other?.userId) ...[
                                                Icon(
                                                  Icons.done_all_rounded,
                                                  size: 15,
                                                  color:
                                                      thread
                                                              .lastMessage!
                                                              .seenAt !=
                                                          null
                                                      ? const Color(0xFF34B7F1)
                                                      : const Color(0xFF94A3B8),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  thread.lastMessage?.content ??
                                                      (isSelf
                                                          ? 'Message yourself'
                                                          : 'No messages yet'),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        (thread.unreadCount >
                                                                0 &&
                                                            !isSelf)
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                              .textSecondary,
                                                    fontWeight:
                                                        (thread.unreadCount >
                                                                0 &&
                                                            !isSelf)
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (thread.unreadCount > 0 && !isSelf)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              thread.unreadCount > 99
                                                  ? '99+'
                                                  : thread.unreadCount
                                                        .toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
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
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 78, right: 20),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
