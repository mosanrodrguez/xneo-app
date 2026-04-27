import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message.dart';

class ChatBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback? onSwipeReply;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isMine,
    this.onSwipeReply,
  });

  Widget _buildMessageStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.waiting:
        return const Icon(Icons.access_time, size: 12, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.grey);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 12, color: Color(0xFFE53935));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine 
        ? const Color(0xFF2A2A3E) 
        : const Color(0xFFE53935).withOpacity(0.15);
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0 && onSwipeReply != null) {
          onSwipeReply!();
        }
      },
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply preview
              if (message.replyToId != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFE53935), width: 3),
                    ),
                  ),
                  child: Text(
                    'Mensaje',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              
              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (message.type == MessageType.image && message.mediaUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.mediaUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    
                    // Audio
                    if (message.type == MessageType.audio)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: message.isPlayed 
                                  ? const Color(0xFFE53935) 
                                  : Colors.grey[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 120,
                            height: 2,
                            color: Colors.grey[600],
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: message.isPlayed ? 0.7 : 0,
                              child: Container(color: const Color(0xFFE53935)),
                            ),
                          ),
                        ],
                      ),
                    
                    // Text
                    if (message.content != null && message.content!.isNotEmpty)
                      Text(
                        message.content!,
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    
                    const SizedBox(height: 2),
                    
                    // Time and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.timestamp, locale: 'es'),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatus(message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
