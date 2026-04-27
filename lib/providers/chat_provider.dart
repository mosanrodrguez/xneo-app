import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';

const API_URL = 'https://xneo-web.onrender.com';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  List<Message> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  List<Chat> get chats => _chats;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUnreadCount {
    return _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  Future<void> fetchChats(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/chats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _chats = data.map((c) => Chat.fromJson(c)).toList();
      } else {
        _error = 'Error al cargar chats';
      }
    } catch (e) {
      _error = 'Error de conexión';
      print('Error fetching chats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String chatId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/chats/$chatId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _currentMessages = data.map((m) => Message.fromJson(m)).toList();
        
        // Marcar como leídos
        await http.put(
          Uri.parse('$API_URL/api/chats/$chatId/read'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        // Actualizar contador de no leídos
        final index = _chats.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          _chats[index] = Chat(
            id: _chats[index].id,
            otherUserId: _chats[index].otherUserId,
            otherUsername: _chats[index].otherUsername,
            otherAvatar: _chats[index].otherAvatar,
            lastMessage: _chats[index].lastMessage,
            lastMessageTime: _chats[index].lastMessageTime,
            unreadCount: 0,
            isOnline: _chats[index].isOnline,
            lastSeen: _chats[index].lastSeen,
            isTyping: _chats[index].isTyping,
            lastMessageStatus: _chats[index].lastMessageStatus,
            lastMessageFromMe: _chats[index].lastMessageFromMe,
          );
        }
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String chatId,
    required String? content,
    required MessageType type,
    required String token,
    String? mediaUrl,
    int? audioDuration,
    String? replyToId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/chats/$chatId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'type': type.name,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          if (audioDuration != null) 'audioDuration': audioDuration,
          if (replyToId != null) 'replyToId': replyToId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _currentMessages.add(Message.fromJson(data));
        
        // Actualizar último mensaje del chat
        final index = _chats.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          _chats[index] = Chat(
            id: _chats[index].id,
            otherUserId: _chats[index].otherUserId,
            otherUsername: _chats[index].otherUsername,
            otherAvatar: _chats[index].otherAvatar,
            lastMessage: content ?? (type == MessageType.image ? '📷 Imagen' : type == MessageType.audio ? '🎤 Audio' : '🎬 Video'),
            lastMessageTime: DateTime.now(),
            unreadCount: _chats[index].unreadCount,
            isOnline: _chats[index].isOnline,
            lastSeen: _chats[index].lastSeen,
            isTyping: _chats[index].isTyping,
            lastMessageStatus: MessageStatus.sent,
            lastMessageFromMe: true,
          );
        }
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return false;
  }

  Future<bool> deleteChats(Set<String> chatIds, String token) async {
    try {
      for (var chatId in chatIds) {
        await http.delete(
          Uri.parse('$API_URL/api/chats/$chatId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
      
      _chats.removeWhere((chat) => chatIds.contains(chat.id));
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting chats: $e');
      return false;
    }
  }

  Future<bool> clearChat(String chatId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$API_URL/api/chats/$chatId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        _currentMessages.clear();
        
        final index = _chats.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          _chats[index] = Chat(
            id: _chats[index].id,
            otherUserId: _chats[index].otherUserId,
            otherUsername: _chats[index].otherUsername,
            otherAvatar: _chats[index].otherAvatar,
            lastMessage: 'Historial eliminado',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            isOnline: _chats[index].isOnline,
            lastSeen: _chats[index].lastSeen,
            isTyping: _chats[index].isTyping,
            lastMessageStatus: null,
            lastMessageFromMe: true,
          );
        }
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error clearing chat: $e');
    }
    return false;
  }
}
