import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'conversation_screen.dart';
import 'users_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Set<String> selectedChats = {};
  bool selectionMode = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadChats();
  }

  Future<void> _loadChats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (auth.token != null) {
      await chatProvider.fetchChats(auth.token!);
    }
  }

  void _toggleSelection(String chatId) {
    setState(() {
      if (selectedChats.contains(chatId)) {
        selectedChats.remove(chatId);
        if (selectedChats.isEmpty) {
          selectionMode = false;
        }
      } else {
        selectedChats.add(chatId);
        selectionMode = true;
      }
    });
  }

  Widget _buildMessageStatusIcon(MessageStatus? status, bool fromMe) {
    if (!fromMe) return const SizedBox.shrink();
    
    switch (status) {
      case MessageStatus.waiting:
        return const Icon(Icons.access_time, size: 14, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.grey);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFFE53935));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: selectionMode
            ? Text('${selectedChats.length} seleccionados', style: const TextStyle(color: Colors.white))
            : const Text('Chats', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: !selectionMode,
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() {
                  selectedChats.clear();
                  selectionMode = false;
                }),
              )
            : null,
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text('Eliminar chats', style: TextStyle(color: Colors.white)),
                        content: Text(
                          '¿Eliminar ${selectedChats.length} chat${selectedChats.length > 1 ? 's' : ''}?',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              chatProvider.deleteChats(selectedChats, auth.token!);
                              setState(() {
                                selectedChats.clear();
                                selectionMode = false;
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFE53935))),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
                  },
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: chatProvider.chats.isEmpty
            ? const Center(
                child: Text('No hay conversaciones aún', style: TextStyle(color: Colors.grey)),
              )
            : ListView.builder(
                itemCount: chatProvider.chats.length,
                itemBuilder: (context, index) {
                  final chat = chatProvider.chats[index];
                  final isSelected = selectedChats.contains(chat.id);
                  return GestureDetector(
                    onTap: () {
                      if (selectionMode) {
                        _toggleSelection(chat.id);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationScreen(
                              chatId: chat.id,
                              otherUserId: chat.otherUserId,
                              otherUsername: chat.otherUsername,
                              otherAvatar: chat.otherAvatar,
                            ),
                          ),
                        );
                      }
                    },
                    onLongPress: () => _toggleSelection(chat.id),
                    child: Container(
                      color: isSelected ? const Color(0xFFE53935).withOpacity(0.1) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFE53935),
                                child: chat.otherAvatar != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: chat.otherAvatar!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        chat.otherUsername[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                              ),
                              if (chat.isOnline)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.otherUsername,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildMessageStatusIcon(chat.lastMessageStatus, chat.lastMessageFromMe),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        chat.lastMessage ?? 'Sin mensajes',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                chat.lastMessageTime != null
                                    ? timeago.format(chat.lastMessageTime!, locale: 'es')
                                    : '',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              if (chat.unreadCount > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    chat.unreadCount.toString(),
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
