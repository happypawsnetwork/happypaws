import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/chat_controller.dart';
import '../../data/models/message.dart';

class ChatThreadScreen extends StatefulWidget {
  final int threadId;
  final int targetUserId;
  final String targetName;
  final String? targetAvatarUrl;
  final bool isSelf;

  const ChatThreadScreen({
    super.key,
    required this.threadId,
    required this.targetUserId,
    required this.targetName,
    this.targetAvatarUrl,
    this.isSelf = false,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ChatController>();
      controller.initialize();
      controller.loadMessages(widget.threadId);
      if (!widget.isSelf) {
        controller.checkBlockStatus(widget.targetUserId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatController?>()?.clearActiveThread();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await context.read<ChatController>().sendMessage(widget.targetUserId, text);
    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share Location',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Current Location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Share your real-time GPS coordinates'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _shareCurrentLocation();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Color(0xFF475569),
                    ),
                  ),
                  title: const Text(
                    'Home Location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Share your registered home address pin',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _shareHomeLocation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareCurrentLocation() async {
    try {
      final locationService = const LocationService();
      final pos = await locationService.getCurrentPosition();
      if (!mounted) return;

      await context.read<ChatController>().sendMessage(
        widget.targetUserId,
        '📍 Current Location',
        lat: pos.latitude,
        lng: pos.longitude,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get current location: $e')),
        );
      }
    }
  }

  Future<void> _shareHomeLocation() async {
    final user = context.read<ProfileController>().userProfile;
    if (user?.homeLatitude == null || user?.homeLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No home location set. Add it in Edit Profile.'),
        ),
      );
      return;
    }

    await context.read<ChatController>().sendMessage(
      widget.targetUserId,
      '🏠 Home Location',
      lat: user!.homeLatitude,
      lng: user.homeLongitude,
    );
    _scrollToBottom();
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  Widget _buildLocationCard(
    Message msg,
    bool isMine,
    Color textColor,
    Color metaColor,
  ) {
    return GestureDetector(
      onTap: () => _openMap(msg.latitude!, msg.longitude!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine
                ? Colors.white.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: isMine ? Colors.white : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg.content.isNotEmpty ? msg.content : 'Pinned Location',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${msg.latitude!.toStringAsFixed(5)}, ${msg.longitude!.toStringAsFixed(5)}',
              style: TextStyle(
                color: metaColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open in Maps',
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: isMine ? Colors.white : AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMine) {
    final isLocation = msg.messageType.toLowerCase() == 'location';
    final bubbleColor = isMine ? AppColors.primary : Colors.white;
    final textColor = isMine ? Colors.white : const Color(0xFF1E293B);
    final metaColor = isMine
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF94A3B8);

    final timeAndStatusWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${msg.sentAt.toLocal().hour.toString().padLeft(2, '0')}:${msg.sentAt.toLocal().minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: metaColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            msg.seenAt != null
                ? Icons.done_all_rounded
                : (msg.deliveredAt != null
                      ? Icons.done_all_rounded
                      : Icons.done_rounded),
            size: 15,
            color: Colors.white,
          ),
        ],
      ],
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isMine ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: isLocation && msg.latitude != null && msg.longitude != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildLocationCard(msg, isMine, textColor, metaColor),
                  const SizedBox(height: 6),
                  timeAndStatusWidget,
                ],
              )
            : Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: timeAndStatusWidget,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDeleteConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.isSelf ? 'Clear saved messages?' : 'Delete conversation?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          widget.isSelf
              ? 'This will permanently remove your saved notes and messages for you.'
              : 'This will permanently remove the conversation with ${widget.targetName} for you. The other participant will not be affected.',
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
              widget.isSelf ? 'Clear' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ChatController>().deleteThread(
        widget.threadId,
      );
      if (mounted && success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isSelf ? 'Saved messages cleared' : 'Conversation deleted',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.watch<ChatController>();
    final iBlocked = chatController.iBlocked;
    final theyBlocked = chatController.theyBlocked;
    final isBlocked = chatController.isBlocked;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  widget.targetAvatarUrl != null &&
                      widget.targetAvatarUrl!.isNotEmpty
                  ? NetworkImage(widget.targetAvatarUrl!)
                  : null,
              child:
                  widget.targetAvatarUrl == null ||
                      widget.targetAvatarUrl!.isEmpty
                  ? Text(
                      widget.targetName.isNotEmpty
                          ? widget.targetName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                    widget.targetName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isSelf ? 'Saved Messages' : 'Direct Message',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (action) async {
              final scaffold = ScaffoldMessenger.of(context);

              if (action == 'block') {
                final success = await chatController.blockUser(
                  widget.targetUserId,
                );
                if (mounted) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'User blocked' : 'Failed to block user',
                      ),
                    ),
                  );
                }
              } else if (action == 'unblock') {
                final success = await chatController.unblockUser(
                  widget.targetUserId,
                );
                if (mounted) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'User unblocked' : 'Failed to unblock user',
                      ),
                    ),
                  );
                }
              } else if (action == 'delete') {
                _confirmDeleteConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isSelf
                          ? 'Clear Saved Messages'
                          : 'Delete Conversation',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              if (!widget.isSelf) ...[
                const PopupMenuDivider(),
                if (iBlocked)
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Unblock User'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Text('Block User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          image: DecorationImage(
            image: AssetImage('assets/images/chat_bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.12,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatController>(
                builder: (context, controller, child) {
                  if (controller.isLoading &&
                      controller.currentMessages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = controller.currentMessages;
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isSelf
                                ? Icons.bookmark_outline_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: widget.isSelf
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.isSelf
                                ? 'Saved Messages'
                                : 'No messages yet',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isSelf
                                ? 'Send notes, reminders, or locations to yourself'
                                : 'Say hello or share a location to coordinate',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = widget.isSelf
                          ? true
                          : (msg.senderId != widget.targetUserId);
                      return _buildMessageBubble(msg, isMine);
                    },
                  );
                },
              ),
            ),
            if (iBlocked)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.block_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You have blocked this user. You cannot send or receive messages from this user.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _confirmDeleteConversation,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Delete Conversation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final scaffold = ScaffoldMessenger.of(context);
                              final success = await context
                                  .read<ChatController>()
                                  .unblockUser(widget.targetUserId);
                              if (mounted) {
                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'User unblocked'
                                          : 'Failed to unblock user',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Unblock User',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (theyBlocked)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You cannot send or receive messages from this user.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: isBlocked
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        size: 26,
                      ),
                      tooltip: 'Share Location',
                      onPressed: isBlocked ? null : _showAttachmentSheet,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          enabled: !isBlocked,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: isBlocked
                                ? (iBlocked
                                      ? 'You blocked this user'
                                      : 'You cannot message this user')
                                : (widget.isSelf
                                      ? 'Message yourself...'
                                      : 'Message...'),
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => isBlocked ? null : _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.grey.shade300
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                        onPressed: isBlocked ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
