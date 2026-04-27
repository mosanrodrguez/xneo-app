import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../services/cache_service.dart';

const API_URL = 'https://xneo-web.onrender.com';

class VideoProvider extends ChangeNotifier {
  List<Video> _videos = [];
  List<Video> _userVideos = [];
  bool _isLoading = false;
  String? _error;

  List<Video> get videos => _videos;
  List<Video> get userVideos => _userVideos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVideos(String? token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse('$API_URL/api/videos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _videos = data.map((v) => Video.fromJson(v)).toList();
        
        // Precargar thumbnails
        for (var video in _videos) {
          if (video.thumbnail != null) {
            VideoCacheService.precacheVideo(video.thumbnail!);
          }
        }
      } else {
        _error = 'Error al cargar videos';
      }
    } catch (e) {
      _error = 'Error de conexión';
      print('Error fetching videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserVideos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/videos/mine'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _userVideos = data.map((v) => Video.fromJson(v)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user videos: $e');
    }
  }

  Future<bool> likeVideo(String videoId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/videos/$videoId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        await fetchVideos(token);
        return true;
      }
    } catch (e) {
      print('Error liking video: $e');
    }
    return false;
  }

  Future<bool> dislikeVideo(String videoId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/videos/$videoId/dislike'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        await fetchVideos(token);
        return true;
      }
    } catch (e) {
      print('Error disliking video: $e');
    }
    return false;
  }

  Future<String?> uploadVideo({
    required String token,
    required String filePath,
    required String title,
    String? description,
    String? category,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_URL/api/videos/upload'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('video', filePath));
      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (category != null) request.fields['category'] = category;
      
      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchVideos(token);
        return null; // Éxito
      } else {
        final data = await response.stream.bytesToString();
        final jsonData = json.decode(data);
        return jsonData['message'] ?? 'Error al subir video';
      }
    } catch (e) {
      return 'Error de conexión al subir video';
    }
  }
}
