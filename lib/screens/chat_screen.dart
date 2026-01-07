/// 💬 GIGMATCH Chat Screen
/// Real-time messaging with matches
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../core/services/services.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final UploadService _uploadService = UploadService();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // Enter chat room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().enterChat(widget.matchId);
    });

    // Scroll listener for loading more
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();

    // Leave chat room
    context.read<ChatProvider>().leaveChat();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more messages when near top (messages are reversed)
      context.read<ChatProvider>().loadMessages(loadMore: true);
    }
  }

  void _onTextChanged(String text) {
    final chatProvider = context.read<ChatProvider>();

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chatProvider.sendTyping();
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      chatProvider.stopTyping();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _isTyping = false;
    context.read<ChatProvider>().stopTyping();

    await context.read<ChatProvider>().sendMessage(text);

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.charcoal,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.offWhite),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer2<MatchProvider, AuthProvider>(
        builder: (context, matchProvider, authProvider, _) {
          final match = matchProvider.getMatchById(widget.matchId);
          if (match == null) return const SizedBox();

          final isArtist = authProvider.isArtist;
          final name = match.getOtherPartyName(isArtist);
          final photo = match.getOtherPartyPhoto(isArtist);

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.graphite,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.mediumGray,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.offWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, _) {
                        if (chatProvider.isOtherUserTyping) {
                          return const Text(
                            'typing...',
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.offWhite),
          onPressed: _showOptions,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer2<ChatProvider, AuthProvider>(
      builder: (context, chatProvider, authProvider, _) {
        if (chatProvider.status == ChatStatus.loading &&
            chatProvider.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.crimson),
          );
        }

        final messages = chatProvider.messages;
        final currentUserId = authProvider.user?.id ?? '';

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: AppColors.mediumGray.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Say hello! 👋',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Latest messages at bottom
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == currentUserId;
            final showAvatar =
                index == messages.length - 1 ||
                messages[index + 1].senderId != message.senderId;

            return _MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: showAvatar,
              onRetry: message.isFailed
                  ? () => chatProvider.retryMessage(message.id)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (!chatProvider.isOtherUserTyping) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _TypingDot(delay: 0),
                    const SizedBox(width: 4),
                    _TypingDot(delay: 150),
                    const SizedBox(width: 4),
                    _TypingDot(delay: 300),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.charcoal,
        border: Border(top: BorderSide(color: AppColors.slate)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.crimson,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Uploading photo...',
                    style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.mediumGray,
                ),
                onPressed: _isUploading ? null : _showAttachmentOptions,
              ),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.graphite,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    onChanged: _onTextChanged,
                    style: const TextStyle(color: AppColors.offWhite),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.mediumGray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return GestureDetector(
                    onTap: chatProvider.isSending ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: chatProvider.isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.offWhite),
              title: const Text(
                'View Profile',
                style: TextStyle(color: AppColors.offWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: AppColors.offWhite),
              title: const Text(
                'Archive Match',
                style: TextStyle(color: AppColors.offWhite),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final success = await context
                    .read<MatchProvider>()
                    .archiveMatch(widget.matchId);
                if (success && mounted) {
                  navigator.pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.crimson),
              title: const Text(
                'Block',
                style: TextStyle(color: AppColors.crimson),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text(
          'Block this match?',
          style: TextStyle(color: AppColors.offWhite),
        ),
        content: const Text(
          'They won\'t be able to contact you anymore.',
          style: TextStyle(color: AppColors.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              final success = await context.read<MatchProvider>().blockMatch(
                widget.matchId,
              );
              if (success && mounted) {
                navigator.pop();
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.offWhite),
              title: const Text(
                'Photo',
                style: TextStyle(color: AppColors.offWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: AppColors.offWhite),
              title: const Text(
                'Audio',
                style: TextStyle(color: AppColors.offWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendAudio();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pick photo from gallery and send as message
  Future<void> _pickAndSendPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final uploadResult = await _uploadService.uploadGalleryImage(file);

      if (mounted) {
        await context.read<ChatProvider>().sendMessage(
          'Photo',
          type: MessageType.image,
          mediaUrl: uploadResult.url,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Pick audio file and send as message
  Future<void> _pickAndSendAudio() async {
    try {
      // For audio, we can use camera option to show file picker behavior
      // Or we could integrate a file picker package for audio files
      // For now, let's show a message that this feature requires additional setup

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Audio recording coming soon! Use voice notes from keyboard.',
          ),
          backgroundColor: AppColors.crimson,
        ),
      );

      // NOTE: To fully implement audio upload, you would:
      // 1. Use file_picker package to select audio files
      // 2. Or use record package to record audio
      // 3. Then upload using _uploadService.uploadAudio(file)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.charcoal,
              child: Icon(Icons.person, size: 14, color: AppColors.mediumGray),
            )
          else if (!isMe)
            const SizedBox(width: 28),

          if (!isMe) const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: message.type == MessageType.image
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.crimson : AppColors.charcoal,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: _buildMessageContent(),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isFailed) ...[
                      GestureDetector(
                        onTap: onRetry,
                        child: const Text(
                          'Failed to send • Tap to retry',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          color: AppColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : message.isSending
                              ? Icons.access_time
                              : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.blue
                              : AppColors.mediumGray,
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: message.mediaUrl != null
              ? Image.network(
                  message.mediaUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: AppColors.charcoal,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: AppColors.charcoal,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.mediumGray,
                          size: 48,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  width: 200,
                  height: 200,
                  color: AppColors.charcoal,
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.mediumGray,
                      size: 48,
                    ),
                  ),
                ),
        );

      case MessageType.audio:
        return Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: isMe ? Colors.white : AppColors.crimson,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice message',
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.offWhite,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : AppColors.crimson)
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.systemNotice:
        return Text(
          message.content,
          style: const TextStyle(
            color: AppColors.mediumGray,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );

      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.offWhite,
            fontSize: 15,
          ),
        );
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Typing Dot Animation
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.mediumGray.withValues(
              alpha: 0.5 + _animation.value * 0.5,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
