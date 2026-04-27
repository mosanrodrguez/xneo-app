import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class VideoCacheService {
  static final cacheManager = DefaultCacheManager();
  static final Map<String, String> _memoryCache = {};
  
  static Future<String?> getCachedVideoUrl(String url) async {
    // Check memory cache first
    if (_memoryCache.containsKey(url)) {
      final path = _memoryCache[url];
      if (path != null && await File(path).exists()) {
        return path;
      }
      _memoryCache.remove(url);
    }
    
    try {
      final file = await cacheManager.getSingleFile(url);
      if (await file.exists()) {
        _memoryCache[url] = file.path;
        return file.path;
      }
    } catch (e) {
      print('Cache miss: $e');
    }
    return null;
  }
  
  static Future<void> precacheVideo(String url) async {
    try {
      await cacheManager.downloadFile(url);
    } catch (e) {
      print('Precache error: $e');
    }
  }
  
  static Future<void> preloadThumbnails(List<String> urls) async {
    for (final url in urls) {
      try {
        await cacheManager.downloadFile(url);
      } catch (e) {
        print('Thumbnail cache error: $e');
      }
    }
  }
  
  static Future<void> clearCache() async {
    _memoryCache.clear();
    await cacheManager.emptyCache();
  }
  
  static Future<int> getCacheSize() async {
    final dir = await getTemporaryDirectory();
    int totalSize = 0;
    if (dir.existsSync()) {
      dir.listSync(recursive: true).forEach((file) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      });
    }
    return totalSize;
  }
  
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}
