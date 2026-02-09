/// 💬 GIGMATCH Chat Provider
/// State management for messaging and real-time chat
library;

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

enum ChatStatus { initial, loading, loaded, sending, error }

class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final ChatSocketService _socketService = ChatSocketService();

  // Cache services
  final MessageCacheService _messageCache = MessageCacheService();
  final PendingMessageQueueService _pendingQueue = PendingMessageQueueService();

  ChatStatus _status = ChatStatus.initial;
  String? _currentMatchId;
  List<Message> _messages = [];
  int _totalUnread = 0;
  Map<String, int> _unreadByMatch = {};
  bool _isOtherUserTyping = false;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSending = false;

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 50;

  // Getters
  ChatStatus get status => _status;
  String? get currentMatchId => _currentMatchId;
  List<Message> get messages => _messages;
  int get totalUnread => _totalUnread;
  Map<String, int> get unreadByMatch => _unreadByMatch;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isConnected => _socketService.isConnected;

  // Cache getters
  MessageCacheService get messageCache => _messageCache;
  PendingMessageQueueService get pendingQueue => _pendingQueue;

  /// 🔌 Initialize WebSocket connection
  Future<void> initSocket() async {
    await _socketService.connect();

    // Set up callbacks
    _socketService.onNewMessage = _handleNewMessage;
    _socketService.onMessageRead = _handleMessageRead;
    _socketService.onTypingStatus = _handleTypingStatus;
    _socketService.onNewMatch = _handleNewMatch;
    _socketService.onConnected = () => notifyListeners();
    _socketService.onDisconnected = () => notifyListeners();
    _socketService.onError = (error) {
      debugPrint('Socket error: $error');
    };
  }

  /// 🚪 Enter a chat room
  Future<void> enterChat(String matchId) async {
    if (_currentMatchId == matchId) return;

    // Leave previous room
    if (_currentMatchId != null) {
      _socketService.leaveRoom(_currentMatchId!);
    }

    _currentMatchId = matchId;
    _messages = [];
    _page = 1;
    _hasMore = true;
    _isOtherUserTyping = false;

    // Join new room
    _socketService.joinRoom(matchId);

    // Load messages
    await loadMessages();

    // Mark as read
    await markAsRead();
  }

  /// 🚶 Leave current chat
  void leaveChat() {
    if (_currentMatchId != null) {
      _socketService.leaveRoom(_currentMatchId!);
      _currentMatchId = null;
      _messages = [];
      _isOtherUserTyping = false;
      notifyListeners();
    }
  }

  /// 📬 Load messages
  Future<void> loadMessages({bool loadMore = false}) async {
    if (_currentMatchId == null || _isLoading) return;
    if (loadMore && !_hasMore) return;

    _isLoading = true;
    _status = _messages.isEmpty ? ChatStatus.loading : _status;
    notifyListeners();

    try {
      // First, load from cache for instant display
      if (!loadMore) {
        final cachedMessages = await _messageCache.getCachedMessages(_currentMatchId!);
        if (cachedMessages.isNotEmpty) {
          _messages = cachedMessages;
          notifyListeners();
        }
      }

      // Then fetch from network
      final response = await _messageService.getMessages(
        matchId: _currentMatchId!,
        page: loadMore ? _page : 1,
        limit: _limit,
      );

      if (loadMore) {
        _messages.addAll(response.messages);
      } else {
        _messages = response.messages;
        _page = 1;
      }

      // Update cache
      await _messageCache.cacheMessages(_currentMatchId!, _messages);

      _hasMore = response.hasMore;
      _page++;
      _status = ChatStatus.loaded;
    } catch (e) {
      debugPrint('Load messages error: $e');
      _errorMessage = 'Failed to load messages';
      _status = ChatStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Load cached messages only (for offline)
  Future<void> loadCachedMessages() async {
    if (_currentMatchId == null) return;

    final cachedMessages = await _messageCache.getCachedMessages(_currentMatchId!);
    if (cachedMessages.isNotEmpty) {
      _messages = cachedMessages;
      notifyListeners();
    }
  }

  /// ✉️ Send a message
  Future<bool> sendMessage(
    String content, {
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentMatchId == null || content.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    // Create optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = Message(
      id: tempId,
      matchId: _currentMatchId!,
      senderId: 'me', // Will be replaced by actual sender ID
      content: content,
      type: type,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      mediaUrl: mediaUrl,
      metadata: metadata,
    );

    // Add to list optimistically
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // Send via REST API
      final sentMessage = await _messageService.sendMessage(
        SendMessageRequest(
          matchId: _currentMatchId!,
          content: content,
          type: type,
          mediaUrl: mediaUrl,
          replyToMessageId: replyToMessageId,
          metadata: metadata,
        ),
      );

      // Replace temp message with real one
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = sentMessage;
      }

      // Update cache
      await _messageCache.addMessage(_currentMatchId!, sentMessage);

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Send message error: $e');

      // Mark as failed
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = tempMessage.copyWith(status: MessageStatus.failed);
      }

      // Add to pending queue for retry
      final pending = PendingMessage(
        tempId: tempId,
        matchId: _currentMatchId!,
        message: tempMessage,
        createdAt: DateTime.now(),
      );
      await _pendingQueue.add(pending);

      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔄 Retry failed message
  Future<bool> retryMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final message = _messages[index];
    if (message.status != MessageStatus.failed) return false;

    // Remove failed message and resend
    _messages.removeAt(index);
    return sendMessage(
      message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
    );
  }

  /// ✅ Mark messages as read
  Future<void> markAsRead() async {
    if (_currentMatchId == null) return;

    try {
      await _messageService.markAsRead(_currentMatchId!);

      // Update local unread count
      _unreadByMatch[_currentMatchId!] = 0;
      _totalUnread = _unreadByMatch.values.fold(0, (a, b) => a + b);
      notifyListeners();
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// ⌨️ Send typing indicator
  void sendTyping() {
    if (_currentMatchId != null) {
      _socketService.sendTyping(_currentMatchId!);
    }
  }

  /// 🛑 Stop typing indicator
  void stopTyping() {
    if (_currentMatchId != null) {
      _socketService.stopTyping(_currentMatchId!);
    }
  }

  /// 🔢 Refresh total unread count
  Future<void> refreshUnreadCount() async {
    try {
      final response = await _messageService.getUnreadCount();
      _totalUnread = response.totalUnread;
      _unreadByMatch = response.byMatch;
      notifyListeners();
    } catch (e) {
      debugPrint('Get unread count error: $e');
    }
  }

  /// 🗑️ Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete message error: $e');
      return false;
    }
  }

  /// 🔌 Disconnect socket
  void disconnect() {
    _socketService.disconnect();
  }

  /// 🔄 Reconnect socket
  Future<void> reconnect() async {
    await _socketService.reconnect();
    if (_currentMatchId != null) {
      _socketService.joinRoom(_currentMatchId!);
    }
  }

  // WebSocket event handlers
  void _handleNewMessage(Message message) {
    // Only add if it's for current chat
    if (message.matchId == _currentMatchId) {
      // Check if message already exists (avoid duplicates)
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.insert(0, message);
        notifyListeners();
      }
    } else {
      // Update unread count for other chats
      _unreadByMatch[message.matchId] =
          (_unreadByMatch[message.matchId] ?? 0) + 1;
      _totalUnread = _unreadByMatch.values.fold(0, (a, b) => a + b);
      notifyListeners();
    }
  }

  void _handleMessageRead(String matchId, String messageId) {
    if (matchId == _currentMatchId) {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.read,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  void _handleTypingStatus(String matchId, bool isTyping) {
    if (matchId == _currentMatchId) {
      _isOtherUserTyping = isTyping;
      notifyListeners();
    }
  }

  void _handleNewMatch(Match match) {
    // This will be handled by MatchProvider
    debugPrint('New match notification: ${match.id}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OFFLINE SYNC METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🔄 Sync pending messages when coming back online
  Future<void> syncPendingMessages() async {
    final pending = await _pendingQueue.getRetryableMessages();

    for (final item in pending) {
      try {
        final sentMessage = await _messageService.sendMessage(
          SendMessageRequest(
            matchId: item.matchId,
            content: item.message.content,
            type: item.message.type,
            mediaUrl: item.message.mediaUrl,
          ),
        );

        // Remove from pending queue
        await _pendingQueue.remove(item.tempId);

        // Update message in list if current match
        if (item.matchId == _currentMatchId) {
          final index = _messages.indexWhere((m) => m.id == item.tempId);
          if (index != -1) {
            _messages[index] = sentMessage;
          }
        }

        debugPrint('Synced pending message: ${item.tempId}');
      } catch (e) {
        await _pendingQueue.incrementRetry(item.tempId);
        debugPrint('Failed to sync pending message: ${item.tempId}');
      }
    }

    notifyListeners();
  }

  /// 🔄 Sync all chat data (call on app start or reconnection)
  Future<void> syncAllChats() async {
    await syncPendingMessages();
    await refreshUnreadCount();
  }

  /// 🧹 Clear all cached data
  Future<void> clearCache() async {
    await _messageCache.clearAll();
    await _pendingQueue.clear();
    debugPrint('Chat cache cleared');
  }
}
