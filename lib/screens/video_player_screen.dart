import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/video.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../providers/download_provider.dart';
import '../services/cache_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isCached = false;
  late Video _currentVideo;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_currentVideo.videoUrl == null) return;

    final cachedPath = await VideoCacheService.getCachedVideoUrl(_currentVideo.videoUrl!);
    
    if (cachedPath != null) {
      _controller = VideoPlayerController.file(File(cachedPath));
      _isCached = true;
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(_currentVideo.videoUrl!));
      VideoCacheService.precacheVideo(_currentVideo.videoUrl!);
    }
    
    await _controller!.initialize();
    setState(() => _isInitialized = true);
    _controller!.play();
    _controller!.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shareVideo() async {
    final url = 'https://xneo-web.onrender.com/play/${_currentVideo.id}';
    await Share.share(
      '${_currentVideo.title}\nMira este video en XNEO: $url',
      subject: _currentVideo.title,
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            
            // Video
            Expanded(
              child: _isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                          },
                          child: VideoPlayer(_controller!),
                        ),
                        if (_isCached)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('En caché', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        if (!_controller!.value.isPlaying)
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 64),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFE53935),
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.black26,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
            ),
            
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentVideo.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${_formatNumber(_currentVideo.views)} vistas', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(timeago.format(_currentVideo.uploadDate, locale: 'es'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    if (_currentVideo.description != null && _currentVideo.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_currentVideo.description!, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.grey)),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A3E)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE53935),
                          backgroundImage: _currentVideo.uploaderAvatar != null
                              ? CachedNetworkImageProvider(_currentVideo.uploaderAvatar!)
                              : null,
                          child: _currentVideo.uploaderAvatar == null
                              ? Text(_currentVideo.uploaderName[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(_currentVideo.uploaderName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A3E)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.thumb_up_outlined, _formatNumber(_currentVideo.likes), () => videoProvider.likeVideo(_currentVideo.id, auth.token!)),
                        _buildActionButton(Icons.thumb_down_outlined, _formatNumber(_currentVideo.dislikes), () => videoProvider.dislikeVideo(_currentVideo.id, auth.token!)),
                        _buildActionButton(Icons.share, 'Compartir', _shareVideo),
                        _buildActionButton(Icons.download, 'Guardar', () {
                          downloadProvider.addDownload(_currentVideo.id, _currentVideo.title, _currentVideo.videoUrl!, _currentVideo.thumbnail);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Descarga iniciada'), backgroundColor: Colors.green));
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Videos recomendados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: videoProvider.videos.length,
                        itemBuilder: (context, index) {
                          final v = videoProvider.videos[index];
                          if (v.id == _currentVideo.id) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentVideo = v;
                                _isInitialized = false;
                                _controller?.dispose();
                                _initPlayer();
                              });
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 80,
                                      color: Colors.grey[900],
                                      child: v.thumbnail != null
                                          ? CachedNetworkImage(imageUrl: v.thumbnail!, fit: BoxFit.cover)
                                          : const Icon(Icons.play_circle_outline, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
