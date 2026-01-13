/// 💬 GIGMATCH Chat Screen
///
/// Real-time chat screen for messaging between artists and venues

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';

/// 💬 Chat Screen - Main Widget
class ChatScreen extends StatefulWidget {
  final String? matchId;
  final String? participantId;
  final String? participantName;
  final String? participantPhoto;

  const ChatScreen({
    super.key,
    this.matchId,
    this.participantId,
    this.participantName,
    this.participantPhoto,
  });

  static const String route = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;

  bool _isSending = false;
  bool _participantOnline = false;
  bool _participantTyping = false;
  List<dynamic> _messages = [];
  String? _conversationId;
  String? _participantName;
  String? _participantPhoto;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();

    try {
      if (widget.matchId != null) {
        await chatProvider.enterChat(widget.matchId!);
        setState(() {
          _conversationId = widget.matchId!;
          _participantName = widget.participantName ?? 'Unknown';
          _participantPhoto = widget.participantPhoto;
          _participantOnline = false; // Default value
        });
      } else if (widget.participantId != null) {
        // For now, use participantId as matchId - this should be handled by the backend
        await chatProvider.enterChat(widget.participantId!);
        setState(() {
          _conversationId = widget.participantId!;
          _participantName = widget.participantName ?? 'Unknown';
          _participantPhoto = widget.participantPhoto;
          _participantOnline = false; // Default value
        });
      }

      await _loadMessages();
    } catch (e) {
      _showError('Failed to load chat');
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.loadMessages();
      // Messages are managed by the provider, no need to set state
      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_conversationId == null) return;

    setState(() => _isSending = true);
    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.sendMessage(content);
      await _loadMessages();
    } catch (e) {
      _showError('Failed to send message');
      _messageController.text = content;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendImage(ImageSource source) async {
    if (_conversationId == null) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendMessage(
          image.path,
          type: MessageType.image,
        );
        await _loadMessages();
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
    } catch (e) {
      _showError('Failed to send image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness, currentUserId),
      body: Column(
        children: [
          if (_participantTyping)
            _buildTypingIndicator(brightness),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChat(brightness)
                : _buildMessagesList(brightness, currentUserId),
          ),
          _buildMessageInput(brightness),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness, String? currentUserId) {
    return AppBar(
      backgroundColor: AppColors.surface(brightness),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(brightness)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildAvatarWithOnlineIndicator(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _participantName ?? 'Chat',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _participantOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _participantOnline ? Colors.green : AppColors.textTert(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithOnlineIndicator() {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _participantOnline ? Colors.green : Colors.transparent,
              width: 2,
            ),
            image: _participantPhoto != null
                ? DecorationImage(image: NetworkImage(_participantPhoto!), fit: BoxFit.cover)
                : null,
            color: AppColors.crimson.withValues(alpha: 0.2),
          ),
          child: _participantPhoto == null
              ? Icon(Icons.person_rounded, color: AppColors.crimson, size: 24)
              : null,
        ),
        if (_participantOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface(Theme.of(context).brightness), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('typing...', style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(Brightness brightness, String? currentUserId) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background(brightness),
                  AppColors.background(brightness).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isOwnMessage = message.senderId == currentUserId;
              return _buildMessageBubble(message, brightness, isOwnMessage);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, Brightness brightness, bool isOwnMessage) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? AppColors.crimson
              : AppColors.surface(brightness).withValues(alpha: 0.95),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isOwnMessage ? 16.0 : 4.0),
            bottomRight: Radius.circular(isOwnMessage ? 4.0 : 16.0),
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(message, brightness),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: (isOwnMessage ? Colors.white70 : AppColors.textTert(brightness)).withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (isOwnMessage) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(dynamic message, Brightness brightness) {
    if (message.type == 'text' || message.type == MessageType.text) {
      return Text(
        message.content,
        style: TextStyle(
          color: message.senderId == context.read<AuthProvider>().user?.id
              ? Colors.white
              : AppColors.text(brightness),
          fontSize: 15,
          height: 1.4,
        ),
      );
    }
    if (message.type == 'image' || message.type == MessageType.image) {
      final imageUrl = message.attachments?.isNotEmpty == true ? message.attachments.first : message.content;
      if (imageUrl?.isNotEmpty == true) {
        return GestureDetector(
          onTap: () {},
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl!, width: 200, height: 150, fit: BoxFit.cover),
          ),
        );
      }
    }
    return Text(message.content, style: TextStyle(color: AppColors.textSec(brightness)));
  }

  Widget _buildMessageInput(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.crimson),
            onPressed: () => _sendImage(ImageSource.gallery),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          _isSending
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimson),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: _messageController.text.trim().isEmpty
                        ? AppColors.textTert(brightness)
                        : AppColors.crimson,
                  ),
                  onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.crimson, AppColors.crimson.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.crimson.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: TextStyle(color: AppColors.text(brightness), fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start chatting',
            style: TextStyle(color: AppColors.textSec(brightness), fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
