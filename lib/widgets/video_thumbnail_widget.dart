import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final String title;
  final String uploaderName;
  final int duration;
  final int views;
  final DateTime uploadDate;
  final String? quality;
  final VoidCallback? onTap;
  final bool showUploader;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    required this.title,
    required this.uploaderName,
    required this.duration,
    required this.views,
    required this.uploadDate,
    this.quality = 'HD',
    this.onTap,
    this.showUploader = true,
  });

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(color: Colors.grey[800]),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.play_circle_outline, 
                              size: 50, 
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.play_circle_outline, size: 50, color: Colors.grey),
                  ),
                  
                  // Calidad
                  if (quality != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quality!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  
                  // Duración
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(duration),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                  
                  // Overlay de play
                  const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 36),
                  ),
                ],
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (showUploader)
                    Text(
                      uploaderName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        _formatViews(views),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text('·', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(uploadDate, locale: 'es'),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
