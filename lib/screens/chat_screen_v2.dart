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
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../core/services/services.dart';
import '../widgets/widgets.dart';
import 'full_screen_media_preview.dart';

class ChatScreenV2 extends StatefulWidget {
  final String? matchId;
  final String? participantId;
  final String? participantName;
  final String? participantPhoto;
  final bool isParticipantArtist;
  final String? replyToMessageId;
  final String? replyToMessageContent;

  /// Pre-resolved chat target (from ChatManager).
  /// When non-null, skip resolution in _initializeChat.
  final ChatTarget? chatTarget;

  const ChatScreenV2({
    super.key,
    this.matchId,
    this.participantId,
    this.participantName,
    this.participantPhoto,
    this.isParticipantArtist = true,
    this.replyToMessageId,
    this.replyToMessageContent,
    this.chatTarget,
  });

  /// Preferred constructor: builds from a pre-resolved [ChatTarget].
  /// The chat screen can render the header immediately without waiting
  /// for any network call.
  factory ChatScreenV2.fromTarget(
    ChatTarget target, {
    Key? key,
    String? replyToMessageId,
    String? replyToMessageContent,
  }) {
    return ChatScreenV2(
      key: key,
      matchId: target.matchId,
      participantId: target.participantId,
      participantName: target.participantName,
      participantPhoto: target.participantPhoto,
      isParticipantArtist: target.isParticipantArtist,
      replyToMessageId: replyToMessageId,
      replyToMessageContent: replyToMessageContent,
      chatTarget: target,
    );
  }

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
  int _recordingDuration = 0;
  String? _conversationId;
  String? _participantName;
  String? _participantPhoto;
  bool _isMuted = false;

  // Voice recorder key for cancel access
  final _voiceRecorderKey = GlobalKey<VoiceRecorderButtonState>();

  // Upload progress (non-blocking inline indicator)
  String? _uploadStatus;

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

  /// Detect Cloudinary resource type from file path and MIME type
  String _detectResourceType(String filePath, String mimeType) {
    final ext = filePath.split('.').last.toLowerCase();

    // Define file type groups
    final imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp', 'svg'};
    final videoExts = {'mp4', 'mov', 'avi', 'webm', 'mkv', '3gp', 'flv', 'wmv'};
    final audioExts = {'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac', 'wma', 'aiff'};

    // Check MIME type first for more accurate detection
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';

    // Fall back to extension detection
    if (imageExts.contains(ext)) return 'image';
    if (videoExts.contains(ext)) return 'video';
    if (audioExts.contains(ext)) return 'audio';

    // Documents default to raw (Cloudinary's non-media type)
    return 'raw';
  }

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();
    final matchProvider = context.read<MatchProvider>();
    final auth = context.read<AuthProvider>();
    final isCurrentUserArtist = auth.isArtist;

    // ── Step 1: Show whatever participant info we already have IMMEDIATELY ──
    // This ensures the header renders even if the API call fails later.
    if (widget.participantName != null || widget.chatTarget != null) {
      setState(() {
        _participantName = widget.chatTarget?.participantName ?? widget.participantName ?? 'Chat';
        _participantPhoto = widget.chatTarget?.participantPhoto ?? widget.participantPhoto;
        _isMuted = widget.chatTarget?.isMuted ?? false;
      });
    }

    // ── Step 2: If we already have a pre-resolved ChatTarget, use it ──
    if (widget.chatTarget != null) {
      debugPrint('💬 [ChatScreenV2] Using pre-resolved ChatTarget: ${widget.chatTarget}');
      try {
        await chatProvider.enterChat(widget.chatTarget!.matchId);
        if (!mounted) return;
        setState(() {
          _conversationId = widget.chatTarget!.matchId;
        });
        return;
      } catch (e) {
        debugPrint('❌ [ChatScreenV2] enterChat failed for target: $e');
        if (mounted) {
          _showError('Failed to load messages. Tap to retry.');
        }
        return;
      }
    }

    // ── Step 3: Resolve via ChatManager (centralized) ──
    try {
      final chatManager = ChatManager.instance;

      // Try to pass a cached match if we have one
      Match? cachedMatch;
      if (widget.matchId != null) {
        cachedMatch = matchProvider.getMatchById(widget.matchId!);
      }

      final target = await chatManager.resolveChat(
        matchId: widget.matchId,
        participantId: widget.participantId,
        participantType: widget.isParticipantArtist ? 'artist' : 'venue',
        participantName: widget.participantName,
        participantPhoto: widget.participantPhoto,
        isParticipantArtist: widget.isParticipantArtist,
        cachedMatch: cachedMatch,
        isCurrentUserArtist: isCurrentUserArtist,
      );

      if (target == null) {
        debugPrint('❌ [ChatScreenV2] ChatManager returned null');
        if (mounted) {
          _showError('Unable to start chat');
        }
        return;
      }

      debugPrint('💬 [ChatScreenV2] Resolved target: $target');

      // Update header with resolved data
      if (!mounted) return;
      setState(() {
        _participantName = target.participantName;
        _participantPhoto = target.participantPhoto;
        _isMuted = target.isMuted;
      });

      // Enter the chat room and load messages
      await chatProvider.enterChat(target.matchId);

      if (!mounted) return;
      setState(() {
        _conversationId = target.matchId;
      });
    } catch (e) {
      debugPrint('❌ [ChatScreenV2] Failed to initialize chat: $e');
      if (mounted) {
        _showError('Failed to load chat. Please go back and try again.');
      }
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
        setState(() => _uploadStatus = 'Uploading image...');
        debugPrint('📤 [ChatScreen] Starting image upload: ${image.path}');

        // Upload image to server first
        final chatService = ChatService();
        final imageUrl = await chatService.uploadMedia(image.path, 'image');
        debugPrint('✅ [ChatScreen] Image uploaded: $imageUrl');

        if (mounted) {
          setState(() => _uploadStatus = null);

          final chatProvider = context.read<ChatProvider>();
          await chatProvider.sendMessage(
            imageUrl,
            type: MessageType.image,
            replyToMessageId: _replyToMessageId,
          );
          _clearReply();
          _scrollToBottom();
        }
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [ChatScreen] Image picker error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to pick image');
    } catch (e) {
      debugPrint('❌ [ChatScreen] Image send error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to send image');
    }
  }

  Future<void> _sendDocument() async {
    if (_conversationId == null) return;

    try {
      // Request file selection
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );
      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
      );

      if (file != null && mounted) {
        HapticFeedback.lightImpact();
        setState(() => _uploadStatus = 'Uploading file...');
        debugPrint('📤 [ChatScreen] Starting document upload: ${file.name}');

        // Detect actual file type for proper Cloudinary upload
        final resourceType = _detectResourceType(file.path, file.mimeType ?? '');
        debugPrint('📤 [ChatScreen] Uploading file as type: $resourceType');

        // Upload file to server with correct resource type
        final chatService = ChatService();
        final uploadedUrl = await chatService.uploadMedia(file.path, resourceType);
        debugPrint('✅ [ChatScreen] Document uploaded: $uploadedUrl');

        if (mounted) {
          setState(() => _uploadStatus = null);

          final chatProvider = context.read<ChatProvider>();
          final fileSize = await file.length();
          await chatProvider.sendMessage(
            '📎 ${file.name}\n$uploadedUrl',
            type: MessageType.text,
            metadata: {
              'documentName': file.name,
              'documentSize': fileSize,
              'documentUrl': uploadedUrl,
              'isDocument': true,
            },
            replyToMessageId: _replyToMessageId,
          );
          _clearReply();
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('❌ [ChatScreen] Document picker error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to send file');
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

      setState(() => _uploadStatus = 'Getting location...');
      debugPrint('📍 [ChatScreen] Getting current location...');

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
        setState(() => _uploadStatus = null);

        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        final mapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
        debugPrint('📍 [ChatScreen] Location resolved: $address');

        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendMessage(
          '📍 $address\n\nView on Maps: $mapsUrl',
          type: MessageType.text,
          metadata: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': address,
            'mapsUrl': mapsUrl,
            'isLocation': true,
          },
          replyToMessageId: _replyToMessageId,
        );
        _clearReply();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ [ChatScreen] Location error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to get location');
    }
  }

  Future<void> _sendAudio(String audioPath, int durationSeconds) async {
    if (_conversationId == null) return;

    setState(() {
      _isSending = true;
      _isRecording = false;
      _recordingDuration = 0;
    });
    HapticFeedback.lightImpact();

    try {
      setState(() => _uploadStatus = 'Sending voice message...');
      debugPrint('📤 [ChatScreen] Starting audio upload: $audioPath (${durationSeconds}s)');

      // Upload audio to server
      final chatService = ChatService();
      final audioUrl = await chatService.uploadMedia(audioPath, 'audio');
      debugPrint('✅ [ChatScreen] Audio uploaded: $audioUrl');

      if (mounted) {
        setState(() => _uploadStatus = null);

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
      debugPrint('❌ [ChatScreen] Audio upload error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to send voice message');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  Future<void> _toggleMute() async {
    if (_conversationId == null) return;

    try {
      final chatService = ChatService();
      if (_isMuted) {
        await chatService.unmuteConversation(_conversationId!);
        setState(() => _isMuted = false);
        _showSuccess('Notifications unmuted');
      } else {
        await chatService.muteConversation(_conversationId!);
        setState(() => _isMuted = true);
        _showSuccess('Notifications muted');
      }
    } catch (e) {
      debugPrint('Mute toggle error: $e');
      _showError('Failed to update mute settings');
    }
  }

  void _showBlockConfirmation() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Block User'),
          ],
        ),
        content: Text(
          'Are you sure you want to block ${_participantName ?? 'this user'}?\n\n'
          'They will not be able to message you and you won\'t see their profile in discovery.',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    if (_conversationId == null) { return; }

    try {
      setState(() => _uploadStatus = 'Blocking user...');
      debugPrint('🚫 [ChatScreen] Blocking user in conversation: $_conversationId');
      final chatService = ChatService();
      await chatService.blockConversation(_conversationId!);
      
      if (mounted) {
        setState(() => _uploadStatus = null);
        // Remove from local matches list (no second API call — blockConversation already set blockedBy correctly)
        final matchProvider = context.read<MatchProvider>();
        matchProvider.removeMatchLocally(_conversationId!);
        
        final nav = Navigator.of(context);
        final scaffold = ScaffoldMessenger.of(context);
        nav.pop(); // Go back to messages
        scaffold.showSnackBar(
          SnackBar(
            content: Text('${_participantName ?? 'User'} has been blocked'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [ChatScreen] Block error: $e');
      if (mounted) {
        setState(() => _uploadStatus = null);
      }
      _showError('Failed to block user');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Ensure proper cleanup when popping
        if (didPop) {
          debugPrint('💬 [ChatScreenV2] Popped, cleaning up...');
        }
      },
      child: Scaffold(
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
        onPressed: () {
          // Ensure we can pop before popping to avoid exiting the app
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
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
                    // Don't show misleading Offline - just show empty or subtle text
                    return const SizedBox.shrink();
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
                _toggleMute();
              },
              leadingIcon: Icon(
                _isMuted ? Icons.notifications_rounded : Icons.notifications_off_outlined,
              ),
              child: Text(_isMuted ? 'Unmute' : 'Mute'),
            ),
            MenuItemButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _showBlockConfirmation();
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
    // Get initials from participant name for fallback
    String initials = 'U';
    if (_participantName != null && _participantName!.isNotEmpty) {
      final parts = _participantName!.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _participantPhoto == null
                ? LinearGradient(
                    colors: [
                      AppColors.crimson,
                      AppColors.crimson.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: _participantPhoto != null && _participantPhoto!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _participantPhoto!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.crimson.withValues(alpha: 0.2),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.crimson,
                            AppColors.crimson.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        // Online indicator - only show when typing (confirmed active)
        Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            if (!chatProvider.isOtherUserTyping) {
              return const SizedBox.shrink();
            }
            return Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface(brightness),
                    width: 2,
                  ),
                ),
              ),
            );
          },
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
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload progress indicator (non-blocking)
            if (_uploadStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.crimson,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _uploadStatus!,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button OR cancel recording button
                if (_isRecording)
                  IconButton(
                    onPressed: _cancelRecording,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: 28,
                    ),
                    tooltip: 'Cancel recording',
                  )
                else
                  IconButton(
                    onPressed: () => _showAttachmentOptions(brightness),
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.crimson,
                      size: 28,
                    ),
                  ),

                // Text input OR recording timer display
                Expanded(
                  child: _isRecording
                      ? Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              // Pulsing red dot
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.3, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Icon(
                                      Icons.fiber_manual_record_rounded,
                                      color: Colors.red,
                                      size: 12,
                                    ),
                                  );
                                },
                                onEnd: () {
                                  // Restart animation
                                  if (mounted && _isRecording) {
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRecordingDuration(_recordingDuration),
                                style: TextStyle(
                                  color: AppColors.crimson,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Recording voice message...',
                                  style: TextStyle(
                                    color: AppColors.textSec(brightness),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: brightness == Brightness.dark
                                ? Colors.grey.shade800.withValues(alpha: 0.5)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _inputFocusNode,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppColors.textTert(brightness),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 15,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                ),

                const SizedBox(width: 8),

                // Send or Voice button — always 48×48 fixed size
                if (hasText || _isSending)
                  ScaleTransition(
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
                else
                  VoiceRecorderButton(
                    key: _voiceRecorderKey,
                    onRecordingComplete: _sendAudio,
                    onRecordingStarted: () =>
                        setState(() {
                          _isRecording = true;
                          _recordingDuration = 0;
                        }),
                    onRecordingCancelled: () =>
                        setState(() {
                          _isRecording = false;
                          _recordingDuration = 0;
                        }),
                    onDurationChanged: (duration) =>
                        setState(() => _recordingDuration = duration),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelRecording() {
    debugPrint('🎙️ [ChatScreen] Cancelling recording');
    _voiceRecorderKey.currentState?.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  String _formatRecordingDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
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
    final isMediaMessage = _isMediaType();

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
              // Message content — media types rendered raw, text gets bubble
              if (isMediaMessage)
                _buildContent(context)
              else
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
                      _buildStatusIcon(context),
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

  /// Check if this message is a media/attachment type (no text bubble needed)
  bool _isMediaType() {
    final metadata = message.metadata;
    if (metadata?['isDocument'] == true) return true;
    if (metadata?['isLocation'] == true) return true;
    if (message.type == MessageType.image) return true;
    if (message.type == MessageType.audio) return true;
    return false;
  }

  Widget _buildContent(BuildContext context) {
    // Check for special content types based on metadata
    final metadata = message.metadata;
    
    // Handle document messages
    if (metadata?['isDocument'] == true) {
      return _buildDocumentContent(context, metadata!);
    }
    
    // Handle location messages
    if (metadata?['isLocation'] == true) {
      return _buildLocationContent(context, metadata!);
    }

    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.audio:
        return _buildAudioContent(context);
      default:
        return _buildTextContent(context);
    }
  }

  Widget _buildTextContent(BuildContext context) {
    // Check if content contains a URL for link preview
    final urlRegex = RegExp(r'https?://[^\s]+');
    final hasUrl = urlRegex.hasMatch(message.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          message.content,
          style: TextStyle(
            color: isOwn ? Colors.white : AppColors.text(brightness),
            fontSize: 15,
            height: 1.4,
          ),
        ),
        if (hasUrl) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isOwn ? Colors.white : AppColors.crimson).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: isOwn ? Colors.white70 : AppColors.crimson,
                ),
                const SizedBox(width: 4),
                Text(
                  'Contains link',
                  style: TextStyle(
                    color: isOwn ? Colors.white70 : AppColors.crimson,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentContent(BuildContext context, Map<String, dynamic> metadata) {
    final documentName = metadata['documentName'] ?? 'Document';
    final documentUrl = metadata['documentUrl'] ?? '';
    final documentSize = metadata['documentSize'] as int?;
    
    String sizeText = '';
    if (documentSize != null) {
      if (documentSize < 1024) {
        sizeText = '$documentSize B';
      } else if (documentSize < 1024 * 1024) {
        sizeText = '${(documentSize / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeText = '${(documentSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    return GestureDetector(
      onTap: () {
        // Launch URL to download document
        _launchUrl(documentUrl);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOwn 
              ? AppColors.crimson
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOwn 
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getDocumentIcon(documentName),
                color: isOwn ? Colors.white : AppColors.crimson,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    documentName,
                    style: TextStyle(
                      color: isOwn ? Colors.white : AppColors.text(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sizeText.isNotEmpty)
                    Text(
                      sizeText,
                      style: TextStyle(
                        color: isOwn 
                            ? Colors.white70 
                            : AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_rounded,
              color: isOwn ? Colors.white70 : AppColors.textSec(brightness),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildLocationContent(BuildContext context, Map<String, dynamic> metadata) {
    final address = metadata['address'] ?? 'Location';
    final mapsUrl = metadata['mapsUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        if (mapsUrl.isNotEmpty) {
          _launchUrl(mapsUrl);
        }
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: isOwn 
              ? AppColors.crimson
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: isOwn 
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: isOwn ? Colors.white : AppColors.crimson,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open map',
                      style: TextStyle(
                        color: isOwn ? Colors.white70 : AppColors.textSec(brightness),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Address
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        color: isOwn ? Colors.white : AppColors.text(brightness),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    color: isOwn ? Colors.white60 : AppColors.textSec(brightness),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // URL launcher is imported via services
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  Widget _buildImageContent(BuildContext context) {
    final imageUrl = message.mediaUrl ?? message.content;

    return GestureDetector(
      onTap: () {
        // Open full-screen preview
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => FullScreenMediaPreview(
              mediaUrl: imageUrl,
              type: ChatMediaType.image,
            ),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      onLongPress: () => _showMessageOptions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 150,
                color: AppColors.surface(brightness),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.crimson,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 150,
                color: AppColors.surface(brightness),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textTert(brightness),
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Failed to load',
                      style: TextStyle(
                        color: AppColors.textTert(brightness),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tap to view overlay
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatusIcon(BuildContext context) {
    // Read receipts (blue double-check) are a Pro feature
    final isPaid = Provider.of<AuthProvider>(context, listen: false).isPaidUser;

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
        // Free users see delivered (grey), Pro users see read (blue)
        if (isPaid) {
          return const Icon(Icons.done_all_rounded, size: 14, color: Colors.blue);
        }
        return Icon(
          Icons.done_all_rounded,
          size: 14,
          color: AppColors.textTert(brightness),
        );
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
