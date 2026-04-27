import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Configuración de Cloudinary (gratuito)
  static const String cloudName = 'dkhhh1vtk';
  static const String uploadPresetVideos = 'xneo_videos';
  static const String uploadPresetImages = 'xneo_images';
  static const String apiKey = 'TU_API_KEY';
  static const String apiSecret = 'TU_API_SECRET';

  /// Sube un video a Cloudinary y devuelve la URL
  static Future<Map<String, dynamic>?> uploadVideo(String filePath, {
    Function(double)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['upload_preset'] = uploadPresetVideos;
      
      // También podríamos generar una miniatura automática
      request.fields['eager'] = 'jpg_thumb';
      request.fields['eager_async'] = 'true';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'url': data['secure_url'],
          'thumbnail': data['eager']?[0]?['secure_url'] ?? data['secure_url']?.replaceAll('.mp4', '.jpg'),
          'duration': data['duration']?.round() ?? 0,
          'publicId': data['public_id'],
          'size': data['bytes'] ?? 0,
          'format': data['format'],
        };
      } else {
        print('Error Cloudinary: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error subiendo a Cloudinary: $e');
      return null;
    }
  }

  /// Sube una imagen a Cloudinary y devuelve la URL
  static Future<String?> uploadImage(String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['upload_preset'] = uploadPresetImages;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'];
      }
    } catch (e) {
      print('Error subiendo imagen: $e');
    }
    return null;
  }

  /// Sube una foto de perfil
  static Future<String?> uploadAvatar(String filePath) async {
    return uploadImage(filePath);
  }

  /// Sube un sticker personalizado
  static Future<String?> uploadSticker(String filePath) async {
    return uploadImage(filePath);
  }

  /// Genera URL de thumbnail para un video
  static String getThumbnailUrl(String videoUrl) {
    // Cloudinary puede generar thumbnails automáticamente
    return videoUrl.replaceAll(RegExp(r'\.\w+$'), '.jpg');
  }
}
