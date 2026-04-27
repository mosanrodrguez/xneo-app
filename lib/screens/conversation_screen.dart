import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/call_provider.dart';
import '../models/message.dart';
import 'call/audio_call_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatar;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatar,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _showStickerPanel = false;
  bool _isReplying = false;
  Message? _replyMessage;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchMessages(widget.chatId, auth.token!);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.waiting:
        return const Icon(Icons.access_time, size: 14, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.grey);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFFE53935));
    }
  }

  Widget _buildMessageBubble(Message message, bool isMine) {
    final bubbleColor = isMine 
        ? const Color(0xFF2A2A3E) 
        : const Color(0xFFE53935).withOpacity(0.15);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() {
              _isReplying = true;
              _replyMessage = message;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyToId != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(left: BorderSide(color: Color(0xFFE53935), width: 3)),
                  ),
                  child: Text('Mensaje', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ),
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
                    if (message.type == MessageType.image && message.mediaUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.mediaUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (message.type == MessageType.audio)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: message.isPlayed ? const Color(0xFFE53935) : Colors.grey[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text('${message.audioDuration ?? 0}s', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    if (message.content != null && message.content!.isNotEmpty)
                      Text(message.content!, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(timeago.format(message.timestamp, locale: 'es'), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
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

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);
    final messages = chatProvider.currentMessages;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE53935),
              child: widget.otherAvatar != null
                  ? ClipOval(child: CachedNetworkImage(imageUrl: widget.otherAvatar!, width: 36, height: 36, fit: BoxFit.cover))
                  : Text(widget.otherUsername[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUsername, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('en línea', style: TextStyle(fontSize: 12, color: Colors.green[400])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFFE53935)),
            onPressed: () {
              callProvider.startCall(widget.otherUserId, widget.otherUsername, widget.otherAvatar);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioCallScreen()));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A2E),
            onSelected: (value) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (value == 'clear') {
                chatProvider.clearChat(widget.chatId, auth.token!);
              } else if (value == 'delete') {
                chatProvider.deleteChats({widget.chatId}, auth.token!);
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.delete_sweep, color: Colors.grey, size: 20), SizedBox(width: 8), Text('Vaciar Chat', style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Color(0xFFE53935), size: 20), SizedBox(width: 8), Text('Eliminar Chat', style: TextStyle(color: Colors.white))])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No hay mensajes aún', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == 'me';
                      return _buildMessageBubble(message, isMine);
                    },
                  ),
          ),
          if (_isReplying && _replyMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1A1A2E),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_replyMessage!.content ?? 'Mensaje', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () => setState(() { _isReplying = false; _replyMessage = null; })),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF1A1A2E),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_showStickerPanel ? Icons.keyboard : Icons.sticky_note_2, color: Colors.grey),
                    onPressed: () => setState(() => _showStickerPanel = !_showStickerPanel),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Mensaje...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFF2A2A3E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        chatProvider.sendMessage(
                          chatId: widget.chatId,
                          content: '',
                          type: MessageType.image,
                          token: auth.token!,
                          mediaUrl: image.path,
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFE53935)),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        chatProvider.sendMessage(
                          chatId: widget.chatId,
                          content: _messageController.text.trim(),
                          type: MessageType.text,
                          token: auth.token!,
                          replyToId: _replyMessage?.id,
                        );
                        _messageController.clear();
                        setState(() { _isReplying = false; _replyMessage = null; });
                        _scrollToBottom();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_showStickerPanel)
            Container(
              height: 100,
              color: const Color(0xFF1A1A2E),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      children: [
                        _buildStickerButton('❤️'),
                        _buildStickerButton('😂'),
                        _buildStickerButton('😍'),
                        _buildStickerButton('🔥'),
                        _buildStickerButton('👍'),
                        _buildStickerButton('🎉'),
                        _buildStickerButton('💯'),
                        _buildStickerButton('⭐'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStickerButton(String emoji) {
    return GestureDetector(
      onTap: () {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.sendMessage(
          chatId: widget.chatId, content: emoji, type: MessageType.text, token: auth.token!,
        );
        _scrollToBottom();
      },
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
