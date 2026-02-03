/// 💬 GIGMATCH Chat Screen V2 - Material 3 Design
///
/// Features:
/// - Material 3 components throughout
/// - Real-time typing indicators
/// - Message status (sent, delivered, read)
/// - Animated message bubbles
/// - Voice message support with upload
/// - Image attachments
/// - Document attachments
/// - Location sharing
/// - Call functionality
/// - Reply to message
///
/// Clean, modern chat experience
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../core/services/services.dart';
import '../widgets/widgets.dart';

class ChatScreenV2 extends StatefulWidget {
  final String? matchId;
  final String? participantId;
  final String? participantName;
  final String? participantPhoto;
  final bool isParticipantArtist;
  final String? replyToMessageId;
  final String? replyToMessageContent;

  const ChatScreenV2({
    super.key,
    this.matchId,
    this.participantId,
    this.participantName,
    this.participantPhoto,
    this.isParticipantArtist = true,
    this.replyToMessageId,
    this.replyToMessageContent,
  });

  static const String route = '/chat';

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;
  late final FocusNode _inputFocusNode;

  // Typing debounce
  Timer? _typingTimer;
  bool _isTyping = false;

  // State
  bool _isSending = false;
  bool _isRecording = false;
  String? _conversationId;
  String? _participantName;
  String? _participantPhoto;
  bool _isParticipantOnline = false;

  // Reply feature
  String? _replyToMessageId;
  String? _replyToMessageContent;

  // Animation
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _inputFocusNode = FocusNode();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    _messageController.addListener(_onTextChanged);

    // Set reply if provided
    _replyToMessageId = widget.replyToMessageId;
    _replyToMessageContent = widget.replyToMessageContent;

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _sendButtonController.dispose();
    _typingTimer?.cancel();

    // Leave chat room
    final chatProvider = context.read<ChatProvider>();
    chatProvider.leaveChat();
    chatProvider.stopTyping();

    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText && !_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().sendTyping();
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatProvider>().stopTyping();
      }
    });

    setState(() {});
  }

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();

    try {
      final matchId = widget.matchId ?? widget.participantId;
      if (matchId != null) {
        String? conversationId;

        // If we have a participantId but no matchId, we need to get or create a conversation
        if (widget.matchId == null && widget.participantId != null) {
          debugPrint('💬 [ChatScreenV2] No existing match, creating conversation...');
          final chatService = ChatService();
          final conversation = await chatService.getOrCreateConversation(
            participantId: widget.participantId!,
            participantType: widget.isParticipantArtist ? 'artist' : 'venue',
          );
          conversationId = conversation.id;
          debugPrint('💬 [ChatScreenV2] Got conversation: $conversationId');
        } else {
          conversationId = matchId;
        }

        await chatProvider.enterChat(conversationId);

        // Use provided name/photo or fetch from backend
        String? participantName = widget.participantName;
        String? participantPhoto = widget.participantPhoto;

        // If participant info is missing, fetch it from the backend
        if ((participantName == null || participantName.isEmpty) &&
            widget.participantId != null) {
          try {
            if (widget.isParticipantArtist) {
              final artistService = ArtistService();
              final artist = await artistService.getArtistById(widget.participantId!);
              participantName = artist.displayName;
              participantPhoto = artist.profilePhoto;
            } else {
              final venueService = VenueService();
              final venue = await venueService.getVenueById(widget.participantId!);
              participantName = venue.venueName;
              participantPhoto = venue.profilePhotoUrl;
            }
          } catch (e) {
            debugPrint('Failed to fetch participant info: $e');
          }
        }

        setState(() {
          _conversationId = conversationId;
          _participantName = participantName ?? 'Chat';
          _participantPhoto = participantPhoto;
          _isParticipantOnline = chatProvider.isConnected;
        });
      }
    } catch (e) {
      debugPrint('❌ [ChatScreenV2] Failed to initialize chat: $e');
      _showError('Failed to load chat');
    }
  }

  void _navigateToParticipantProfile() {
    final participantId = widget.participantId ?? widget.matchId;
    if (participantId == null || participantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not available')),
      );
      return;
    }

    final route = widget.isParticipantArtist
        ? '/artist/$participantId'
        : '/venue/$participantId';

    Navigator.of(context, rootNavigator: true).pushNamed(route);
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
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _conversationId == null) return;

    // Cache provider before async gap
    final chatProvider = context.read<ChatProvider>();

    // Animate button
    await _sendButtonController.forward();
    _sendButtonController.reverse();

    HapticFeedback.lightImpact();

    setState(() => _isSending = true);
    final replyId = _replyToMessageId;
    _messageController.clear();
    _replyToMessageId = null;
    _replyToMessageContent = null;
    _isTyping = false;
    chatProvider.stopTyping();

    try {
      final success = await chatProvider.sendMessage(
        content,
        replyToMessageId: replyId,
      );
      if (success) {
        _scrollToBottom();
      } else {
        _showError('Failed to send message');
        _messageController.text = content;
        _replyToMessageId = replyId;
        _replyToMessageContent = widget.replyToMessageContent;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

      if (image != null && mounted) {
        HapticFeedback.lightImpact();
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendMessage(
          image.path,
          type: MessageType.image,
          replyToMessageId: _replyToMessageId,
        );
        _clearReply();
        _scrollToBottom();
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
      _showError('Failed to pick image');
    } catch (e) {
      _showError('Failed to send image');
    }
  }

  Future<void> _sendDocument() async {
    if (_conversationId == null) return;

    try {
      // Request file selection
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
      );

      if (file != null && mounted) {
        HapticFeedback.lightImpact();
        _showLoading('Uploading document...');

        // Upload file to server
        final chatService = ChatService();
        final uploadedUrl = await chatService.uploadMedia(file.path, 'document');

        if (mounted) {
          Navigator.of(context).pop(); // Remove loading dialog

          final chatProvider = context.read<ChatProvider>();
          await chatProvider.sendMessage(
            uploadedUrl,
            type: MessageType.text,
            metadata: {
              'documentName': file.name,
              'documentSize': file.length,
            },
            replyToMessageId: _replyToMessageId,
          );
          _clearReply();
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Document picker error: $e');
      _showError('Failed to send document');
    }
  }

  Future<void> _sendLocation() async {
    if (_conversationId == null) return;

    try {
      // Check location permission
      final permission = await Permission.location.status;
      if (permission.isDenied) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          _showError('Location permission is required');
          return;
        }
      }

      _showLoading('Getting location...');

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog

        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';

        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendMessage(
          address,
          type: MessageType.text,
          metadata: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': address,
          },
          replyToMessageId: _replyToMessageId,
        );
        _clearReply();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) Navigator.of(context).pop();
      _showError('Failed to get location');
    }
  }

  Future<void> _sendAudio(String audioPath, int durationSeconds) async {
    if (_conversationId == null) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      _showLoading('Uploading voice message...');

      // Upload audio to server
      final chatService = ChatService();
      final audioUrl = await chatService.uploadMedia(audioPath, 'audio');

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog

        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendMessage(
          audioUrl,
          type: MessageType.audio,
          metadata: {'duration': durationSeconds},
          replyToMessageId: _replyToMessageId,
        );
        _clearReply();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Audio upload error: $e');
      if (mounted) Navigator.of(context).pop();
      _showError('Failed to send voice message');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.crimson),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setReply(String? messageId, String? messageContent) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToMessageContent = messageContent;
    });
    _inputFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToMessageContent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: Column(
        children: [
          // Typing indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.isOtherUserTyping) {
                return _TypingIndicator(
                  name: _participantName ?? 'User',
                  brightness: brightness,
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.status == ChatStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.crimson),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return _buildEmptyChat(brightness);
                }

                return _buildMessagesList(
                  chatProvider.messages,
                  brightness,
                  currentUserId,
                );
              },
            ),
          ),

          // Reply banner
          if (_replyToMessageId != null)
            _buildReplyBanner(brightness),

          // Input area
          _buildInputArea(brightness),
        ],
      ),
    );
  }

  Widget _buildReplyBanner(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: AppColors.crimson.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.crimson,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.crimson,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyToMessageContent ?? 'Message',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.text(brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.textSec(brightness)),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔝 APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.surface(brightness),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(brightness)),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar
          _buildAvatar(brightness),
          const SizedBox(width: 12),

          // Name & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _participantName ?? 'Chat',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.isOtherUserTyping) {
                      return Text(
                        'typing...',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return Text(
                      _isParticipantOnline ? 'Online' : 'Offline',
                      style: AppTypography.bodySmall.copyWith(
                        color: _isParticipantOnline ? Colors.green : AppColors.textTert(brightness),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // More options
        MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.text(brightness),
              ),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          style: MenuStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _navigateToParticipantProfile();
              },
              leadingIcon: const Icon(Icons.person_outline_rounded),
              child: const Text('View Profile'),
            ),
            MenuItemButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                // TODO: Implement mute
                _showError('Mute notifications coming soon!');
              },
              leadingIcon: const Icon(Icons.notifications_off_outlined),
              child: const Text('Mute'),
            ),
            MenuItemButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                // TODO: Implement block
                _showError('Block user coming soon!');
              },
              leadingIcon: const Icon(
                Icons.block_rounded,
                color: AppColors.error,
              ),
              child: const Text(
                'Block',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(Brightness brightness) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surface(brightness),
          backgroundImage: _participantPhoto != null
              ? CachedNetworkImageProvider(_participantPhoto!)
              : null,
          child: _participantPhoto == null
              ? Icon(
                  Icons.person_rounded,
                  color: AppColors.textSec(brightness),
                  size: 24,
                )
              : null,
        ),
        // Online indicator
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isParticipantOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface(brightness),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 MESSAGES LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessagesList(
    List<Message> messages,
    Brightness brightness,
    String? currentUserId,
  ) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isOwn = message.senderId == currentUserId;

          // Check if we should show date header
          final showDate =
              index == messages.length - 1 ||
              !_isSameDay(message.createdAt, messages[index + 1].createdAt);

          return Column(
            children: [
              if (showDate)
                _DateHeader(date: message.createdAt, brightness: brightness),
              _MessageBubble(
                message: message,
                isOwn: isOwn,
                brightness: brightness,
                onRetry: () =>
                    context.read<ChatProvider>().retryMessage(message.id),
                onReply: () => _setReply(message.id, message.content),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⌨️ INPUT AREA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInputArea(Brightness brightness) {
    if (_isRecording) {
      return VoiceRecorderButton(
        onRecordingComplete: (path, duration) {
          setState(() => _isRecording = false);
          _sendAudio(path, duration);
        },
        onRecordingStarted: () => setState(() => _isRecording = true),
        onRecordingCancelled: () => setState(() => _isRecording = false),
      );
    }

    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        border: Border(
          top: BorderSide(color: AppColors.border(brightness), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              onPressed: () => _showAttachmentOptions(brightness),
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.crimson,
                size: 28,
              ),
            ),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.background(brightness),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: AppColors.textTert(brightness)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(color: AppColors.text(brightness)),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send or Voice button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: hasText || _isSending
                  ? ScaleTransition(
                      key: const ValueKey('send'),
                      scale: _sendButtonScale,
                      child: FilledButton(
                        onPressed: _isSending ? null : _sendMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    )
                  : VoiceRecorderButton(
                      key: const ValueKey('voice'),
                      onRecordingComplete: _sendAudio,
                      onRecordingStarted: () =>
                          setState(() => _isRecording = true),
                      onRecordingCancelled: () =>
                          setState(() => _isRecording = false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(Brightness brightness) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendImage(ImageSource.gallery);
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendImage(ImageSource.camera);
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendDocument();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendLocation();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📭 EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyChat(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: 48,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Say hello! 👋',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with ${_participantName ?? 'them'}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSec(brightness),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ⌨️ TYPING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  final String name;
  final Brightness brightness;

  const _TypingIndicator({required this.name, required this.brightness});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface(widget.brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(widget.brightness)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated dots
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value = ((_controller.value + delay) % 1.0);
                        final scale = 0.5 + (0.5 * _bounce(value));

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withValues(
                                alpha: 0.4 + (0.6 * _bounce(value)),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.name} is typing',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSec(widget.brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _bounce(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      return 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📅 DATE HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final Brightness brightness;

  const _DateHeader({required this.date, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSec(brightness),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final Brightness brightness;
  final VoidCallback? onRetry;
  final VoidCallback? onReply;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.brightness,
    this.onRetry,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = message.status == MessageStatus.failed;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message content
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isOwn
                      ? (isFailed
                            ? Colors.red.withValues(alpha: 0.8)
                            : AppColors.crimson)
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOwn ? 18 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 18),
                  ),
                  border: isOwn
                      ? null
                      : Border.all(color: AppColors.border(brightness)),
                ),
                child: _buildContent(context),
              ),

              // Time & status
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTert(brightness),
                        fontSize: 11,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(),
                    ],
                  ],
                ),
              ),

              // Retry button for failed messages
              if (isFailed && onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.audio:
        return _buildAudioContent(context);
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isOwn ? Colors.white : AppColors.text(brightness),
            fontSize: 15,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    final imageUrl = message.mediaUrl ?? message.content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 150,
          color: AppColors.surface(brightness),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.crimson,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 150,
          color: AppColors.surface(brightness),
          child: Icon(
            Icons.broken_image_rounded,
            color: AppColors.textTert(brightness),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioContent(BuildContext context) {
    // Use mediaUrl for audio if available (uploaded URL)
    String audioUrl = message.mediaUrl ?? message.content;
    int? durationSeconds;

    // Try to get duration from metadata first
    durationSeconds = message.metadata?['duration'] as int?;

    // Fallback: parse from content if it contains duration (old format)
    if (durationSeconds == null && message.content.contains('|')) {
      final parts = message.content.split('|');
      audioUrl = parts[0];
      durationSeconds = int.tryParse(parts[1]);
    }

    return SizedBox(
      width: 200,
      child: AudioMessageBubble(
        audioUrl: audioUrl,
        durationSeconds: durationSeconds,
        isOwnMessage: isOwn,
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time_rounded,
          size: 14,
          color: AppColors.textTert(brightness),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check_rounded,
          size: 14,
          color: AppColors.textTert(brightness),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          size: 14,
          color: AppColors.textTert(brightness),
        );
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: Colors.red,
        );
    }
  }

  void _showMessageOptions(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            // Reply option
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatProvider>().deleteMessage(message.id);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📎 ATTACHMENT OPTION
// ═══════════════════════════════════════════════════════════════════════════

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.text(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
