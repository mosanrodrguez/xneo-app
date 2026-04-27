import 'message.dart';

class Chat {
  final String id;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String? lastSeen;
  final bool isTyping;
  final MessageStatus? lastMessageStatus;
  final bool lastMessageFromMe;

  Chat({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
    this.lastMessageStatus,
    this.lastMessageFromMe = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'] ?? json['id'] ?? '',
      otherUserId: json['otherUserId'] ?? json['other_user_id'] ?? '',
      otherUsername: json['otherUsername'] ?? json['other_username'] ?? '',
      otherAvatar: json['otherAvatar'] ?? json['other_avatar'],
      lastMessage: json['lastMessage'] ?? json['last_message'],
      lastMessageTime: DateTime.tryParse(json['lastMessageTime'] ?? json['last_message_time'] ?? ''),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
      lastSeen: json['lastSeen'] ?? json['last_seen'],
      isTyping: json['isTyping'] ?? json['is_typing'] ?? false,
      lastMessageStatus: MessageStatus.values.firstWhere(
        (s) => s.name == (json['lastMessageStatus'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      lastMessageFromMe: json['lastMessageFromMe'] ?? json['last_message_from_me'] ?? false,
    );
  }
}
