import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/video.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/download_task.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'xneo.db');
    
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE videos (
            id TEXT PRIMARY KEY,
            title TEXT,
            video_url TEXT,
            thumbnail TEXT,
            views INTEGER DEFAULT 0,
            likes INTEGER DEFAULT 0,
            dislikes INTEGER DEFAULT 0,
            duration INTEGER DEFAULT 0,
            category TEXT,
            uploader_name TEXT,
            uploader_avatar TEXT,
            user_id TEXT,
            price REAL DEFAULT 0.0,
            upload_date TEXT,
            description TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            other_user_id TEXT,
            other_username TEXT,
            other_avatar TEXT,
            last_message TEXT,
            last_message_time TEXT,
            unread_count INTEGER DEFAULT 0,
            is_online INTEGER DEFAULT 0,
            last_seen TEXT,
            is_typing INTEGER DEFAULT 0,
            last_message_status TEXT,
            last_message_from_me INTEGER DEFAULT 0
          )
        ''');
        
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            chat_id TEXT,
            sender_id TEXT,
            content TEXT,
            media_url TEXT,
            type TEXT DEFAULT 'text',
            timestamp TEXT,
            status TEXT DEFAULT 'sent',
            reply_to_id TEXT,
            audio_duration INTEGER,
            is_played INTEGER DEFAULT 0
          )
        ''');
        
        await db.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            video_id TEXT,
            title TEXT,
            thumbnail TEXT,
            url TEXT,
            file_path TEXT,
            total_size INTEGER DEFAULT 0,
            downloaded_size INTEGER DEFAULT 0,
            speed REAL DEFAULT 0.0,
            progress INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending'
          )
        ''');
      },
    );
  }

  // Video operations
  static Future<void> saveVideos(List<Video> videos) async {
    final db = await database;
    final batch = db.batch();
    for (var video in videos) {
      batch.insert('videos', {
        'id': video.id,
        'title': video.title,
        'video_url': video.videoUrl,
        'thumbnail': video.thumbnail,
        'views': video.views,
        'likes': video.likes,
        'dislikes': video.dislikes,
        'duration': video.duration,
        'category': video.category,
        'uploader_name': video.uploaderName,
        'uploader_avatar': video.uploaderAvatar,
        'user_id': video.userId,
        'price': video.price,
        'upload_date': video.uploadDate.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
  
  static Future<List<Video>> getCachedVideos() async {
    final db = await database;
    final maps = await db.query('videos');
    return maps.map((m) => Video.fromJson(m)).toList();
  }

  // Chat operations
  static Future<void> saveChats(List<Chat> chats) async {
    final db = await database;
    final batch = db.batch();
    for (var chat in chats) {
      batch.insert('chats', {
        'id': chat.id,
        'other_user_id': chat.otherUserId,
        'other_username': chat.otherUsername,
        'other_avatar': chat.otherAvatar,
        'last_message': chat.lastMessage,
        'last_message_time': chat.lastMessageTime?.toIso8601String(),
        'unread_count': chat.unreadCount,
        'is_online': chat.isOnline ? 1 : 0,
        'last_seen': chat.lastSeen,
        'is_typing': chat.isTyping ? 1 : 0,
        'last_message_status': chat.lastMessageStatus?.name,
        'last_message_from_me': chat.lastMessageFromMe ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
  
  static Future<List<Chat>> getCachedChats() async {
    final db = await database;
    final maps = await db.query('chats', orderBy: 'last_message_time DESC');
    return maps.map((m) => Chat.fromJson(m)).toList();
  }

  // Message operations
  static Future<void> saveMessages(String chatId, List<Message> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var message in messages) {
      batch.insert('messages', message.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
  
  static Future<List<Message>> getCachedMessages(String chatId) async {
    final db = await database;
    final maps = await db.query('messages', 
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Message.fromJson(m)).toList();
  }

  // Download operations
  static Future<void> saveDownloads(List<DownloadTask> downloads) async {
    final db = await database;
    final batch = db.batch();
    for (var download in downloads) {
      batch.insert('downloads', {
        'id': download.id,
        'video_id': download.videoId,
        'title': download.title,
        'thumbnail': download.thumbnail,
        'url': download.url,
        'file_path': download.filePath,
        'total_size': download.totalSize,
        'downloaded_size': download.downloadedSize,
        'speed': download.speed,
        'progress': download.progress,
        'status': download.status.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('videos');
    await db.delete('chats');
    await db.delete('messages');
    await db.delete('downloads');
  }
}
