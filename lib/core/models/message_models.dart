/// 💬 GIGMATCH Message & Chat Models
/// Models for real-time messaging
library;

/// Message Type
enum MessageType {
  text('text'),
  image('image'),
  audio('audio'),
  systemNotice('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MessageType.text,
    );
  }
}

/// Message Status
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  final String value;
  const MessageStatus(this.value);

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Message Model
class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String? senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.readAt,
    this.mediaUrl,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      matchId: json['matchId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'],
      content: json['content'] ?? '',
      type: MessageType.fromString(json['type'] ?? 'text'),
      status: MessageStatus.fromString(json['status'] ?? 'sent'),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      mediaUrl: json['mediaUrl'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'type': type.value,
    'status': status.value,
    'createdAt': createdAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
    'mediaUrl': mediaUrl,
    'metadata': metadata,
  };

  bool get isRead => readAt != null || status == MessageStatus.read;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;

  Message copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Send Message Request
class SendMessageRequest {
  final String matchId;
  final String content;
  final MessageType type;
  final String? mediaUrl;

  SendMessageRequest({
    required this.matchId,
    required this.content,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'content': content,
    'type': type.value,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
  };
}

/// Messages Response (paginated)
class MessagesResponse {
  final List<Message> messages;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  MessagesResponse({
    required this.messages,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      messages: (json['messages'] ?? json['data'] ?? [])
          .map<Message>((e) => Message.fromJson(e))
          .toList(),
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Unread Count Response
class UnreadCountResponse {
  final int totalUnread;
  final Map<String, int> byMatch; // matchId -> unread count

  UnreadCountResponse({required this.totalUnread, this.byMatch = const {}});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    final byMatchRaw = json['byMatch'] as Map<String, dynamic>? ?? {};
    return UnreadCountResponse(
      totalUnread: json['totalUnread'] ?? json['count'] ?? 0,
      byMatch: byMatchRaw.map((k, v) => MapEntry(k, v as int)),
    );
  }
}

/// Chat Room Info (for WebSocket connection)
class ChatRoom {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final List<Message> messages;
  final bool isTyping;
  final DateTime? lastSeen;

  ChatRoom({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.messages = const [],
    this.isTyping = false,
    this.lastSeen,
  });

  ChatRoom copyWith({
    String? matchId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    List<Message>? messages,
    bool? isTyping,
    DateTime? lastSeen,
  }) {
    return ChatRoom(
      matchId: matchId ?? this.matchId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// WebSocket Events
class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String messageRead = 'message_read';
  static const String typing = 'typing';
  static const String stopTyping = 'stop_typing';
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';
  static const String newMatch = 'new_match';
  static const String error = 'error';
}
