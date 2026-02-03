/// 💬 GIGMATCH Message Service
/// Handles messaging operations and WebSocket chat
library;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api/api.dart';
import '../models/models.dart';

class MessageService {
  final ApiClient _client = ApiClient();

  /// 📬 Get messages for a match
  Future<MessagesResponse> getMessages({
    required String matchId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        Endpoints.messagesGet,
        queryParameters: {
          'matchId': matchId,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return MessagesResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get messages error: $e');
      rethrow;
    }
  }

  /// ✉️ Send a message
  Future<Message> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.messagesSend,
        data: request.toJson(),
      );
      return Message.fromJson(response.data);
    } catch (e) {
      debugPrint('Send message error: $e');
      rethrow;
    }
  }

  /// ✅ Mark messages as read
  Future<void> markAsRead(String matchId) async {
    try {
      await _client.post(Endpoints.messagesRead, data: {'matchId': matchId});
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// 🗑️ Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.delete(Endpoints.messageDelete(messageId));
    } catch (e) {
      debugPrint('Delete message error: $e');
      rethrow;
    }
  }

  /// 🔢 Get total unread count
  Future<UnreadCountResponse> getUnreadCount() async {
    try {
      final response = await _client.get(Endpoints.messagesUnreadCount);
      return UnreadCountResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return UnreadCountResponse(totalUnread: 0);
    }
  }
}

/// 🔌 WebSocket Chat Service
class ChatSocketService {
  static ChatSocketService? _instance;
  io.Socket? _socket;
  final ApiClient _client = ApiClient();

  // Callbacks
  Function(Message)? onNewMessage;
  Function(String matchId, String messageId)? onMessageRead;
  Function(String matchId, bool isTyping)? onTypingStatus;
  Function(Match)? onNewMatch;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  factory ChatSocketService() => _instance ??= ChatSocketService._internal();
  ChatSocketService._internal();

  bool get isConnected => _socket?.connected ?? false;

  /// 🔗 Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('WebSocket already connected');
      return;
    }

    final token = await _client.getAccessToken();
    if (token == null) {
      debugPrint('No token available for WebSocket connection');
      return;
    }

    try {
      _socket = io.io(
        ApiConfig.wsUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _setupListeners();

      debugPrint('WebSocket connecting to ${ApiConfig.wsUrl}');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      onError?.call(e);
    }
  }

  /// 🔌 Setup event listeners
  void _setupListeners() {
    _socket?.on(SocketEvents.connect, (_) {
      debugPrint('✅ WebSocket connected');
      onConnected?.call();
    });

    _socket?.on(SocketEvents.disconnect, (_) {
      debugPrint('❌ WebSocket disconnected');
      onDisconnected?.call();
    });

    _socket?.on(SocketEvents.newMessage, (data) {
      debugPrint('📬 New message received');
      try {
        final message = Message.fromJson(data);
        onNewMessage?.call(message);
      } catch (e) {
        debugPrint('Error parsing message: $e');
      }
    });

    _socket?.on(SocketEvents.messageRead, (data) {
      debugPrint('👁️ Message read');
      final matchId = data['matchId'] as String?;
      final messageId = data['messageId'] as String?;
      if (matchId != null && messageId != null) {
        onMessageRead?.call(matchId, messageId);
      }
    });

    _socket?.on(SocketEvents.typing, (data) {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        onTypingStatus?.call(matchId, true);
      }
    });

    // Also listen for user_typing event from backend
    _socket?.on('user_typing', (data) {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        onTypingStatus?.call(matchId, true);
      }
    });

    _socket?.on(SocketEvents.stopTyping, (data) {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        onTypingStatus?.call(matchId, false);
      }
    });

    // Also listen for stop_user_typing event from backend
    _socket?.on('stop_user_typing', (data) {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        onTypingStatus?.call(matchId, false);
      }
    });

    _socket?.on(SocketEvents.newMatch, (data) {
      debugPrint('🎉 New match!');
      try {
        final match = Match.fromJson(data);
        onNewMatch?.call(match);
      } catch (e) {
        debugPrint('Error parsing match: $e');
      }
    });

    _socket?.on(SocketEvents.error, (data) {
      debugPrint('❌ WebSocket error: $data');
      onError?.call(data);
    });
  }

  /// 🚪 Join a chat room (match)
  void joinRoom(String matchId) {
    _socket?.emit(SocketEvents.joinRoom, {'matchId': matchId});
    debugPrint('Joined room: $matchId');
  }

  /// 🚶 Leave a chat room
  void leaveRoom(String matchId) {
    _socket?.emit(SocketEvents.leaveRoom, {'matchId': matchId});
    debugPrint('Left room: $matchId');
  }

  /// ✉️ Send message via WebSocket
  void sendMessage(
    String matchId,
    String content, {
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    _socket?.emit(SocketEvents.sendMessage, {
      'matchId': matchId,
      'content': content,
      'type': type.value,
      if (mediaUrl case final m?) 'mediaUrl': m,
    });
  }

  /// ✅ Mark message as read
  void markAsRead(String matchId, String messageId) {
    _socket?.emit(SocketEvents.messageRead, {
      'matchId': matchId,
      'messageId': messageId,
    });
  }

  /// ⌨️ Send typing indicator
  void sendTyping(String matchId) {
    _socket?.emit(SocketEvents.typing, {'matchId': matchId});
  }

  /// 🛑 Stop typing indicator
  void stopTyping(String matchId) {
    _socket?.emit(SocketEvents.stopTyping, {'matchId': matchId});
  }

  /// 🔌 Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('WebSocket disconnected and disposed');
  }

  /// 🔄 Reconnect to WebSocket
  Future<void> reconnect() async {
    disconnect();
    await connect();
  }
}
