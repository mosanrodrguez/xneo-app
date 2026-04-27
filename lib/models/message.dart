enum MessageStatus {
  waiting,
  sent,
  delivered,
  seen,
}

enum MessageType {
  text,
  image,
  video,
  audio,
  sticker,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String? mediaUrl;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToId;
  final int? audioDuration;
  final bool isPlayed;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.audioDuration,
    this.isPlayed = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      chatId: json['chatId'] ?? json['chat_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      content: json['content'],
      mediaUrl: json['mediaUrl'] ?? json['media_url'],
      type: MessageType.values.firstWhere(
        (t) => t.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      replyToId: json['replyToId'] ?? json['reply_to_id'],
      audioDuration: json['audioDuration'] ?? json['audio_duration'],
      isPlayed: json['isPlayed'] ?? json['is_played'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'mediaUrl': mediaUrl,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'replyToId': replyToId,
      'audioDuration': audioDuration,
      'isPlayed': isPlayed,
    };
  }
}
