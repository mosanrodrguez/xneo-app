import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../providers/chat_provider.dart';
import '../models/video.dart';
import 'video_player_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';
import 'chats_screen.dart';
import 'downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (auth.token != null) {
      await videoProvider.fetchVideos(auth.token);
      await chatProvider.fetchChats(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    final screens = [
      _HomeContent(videos: videoProvider.videos, isLoading: videoProvider.isLoading, onRefresh: _loadData),
      const ChatsScreen(),
      const UploadScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0D0D0D),
          selectedItemColor: const Color(0xFFE53935),
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (chatProvider.totalUnreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chatProvider.totalUnreadCount.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Subir'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final List<Video> videos;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _HomeContent({required this.videos, required this.isLoading, required this.onRefresh});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openUploadVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }

  void _openDownloads() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'X', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
              TextSpan(text: 'NEO', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D0D0D),
        actions: [
          // Botón de descargas (flecha hacia abajo)
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Descargas',
            onPressed: _openDownloads,
          ),
          // Botón de subir video
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFFE53935)),
            tooltip: 'Subir video',
            onPressed: _openUploadVideo,
          ),
        ],
      ),
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : widget.videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay videos disponibles', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onRefresh,
                        child: const Text('Actualizar', style: TextStyle(color: Color(0xFFE53935))),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    widget.onRefresh();
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55, // Más alto para acomodar avatar
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.videos.length,
                    itemBuilder: (context, index) {
                      final video = widget.videos[index];
                      return VideoCard(video: video);
                    },
                  ),
                ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final Video video;
  const VideoCard({super.key, required this.video});

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min >= 60) {
      final hours = min ~/ 60;
      final remainingMin = min % 60;
      return '$hours:${remainingMin.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Hace instantes';
    if (diff.inMinutes == 1) return 'Hace 1 minuto';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} minutos';
    if (diff.inHours == 1) return 'Hace 1 hora';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays == 1) return 'Hace 1 día';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return 'Hace ${(diff.inDays / 365).floor()} años';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === MINIATURA ===
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  // Imagen de fondo
                  Container(
                    height: 130,
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: video.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnail!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.play_circle_outline, color: Colors.grey, size: 40),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.video_library, size: 50, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.video_library, size: 50, color: Colors.grey),
                  ),
                  
                  // Calidad HD en esquina superior derecha
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HD',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  
                  // Duración en esquina inferior derecha
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
                        _formatDuration(video.duration),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // === TÍTULO ===
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            
            // === AVATAR + NOMBRE DEL UPLOADER ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFE53935),
                    backgroundImage: video.uploaderAvatar != null
                        ? CachedNetworkImageProvider(video.uploaderAvatar!)
                        : null,
                    child: video.uploaderAvatar == null
                        ? Text(
                            video.uploaderName.isNotEmpty 
                                ? video.uploaderName[0].toUpperCase() 
                                : 'U',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  // Nombre
                  Expanded(
                    child: Text(
                      video.uploaderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // === ESTADÍSTICAS ===
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    _formatNumber(video.views),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '·',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.access_time, size: 10, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      _formatTimeAgo(video.uploadDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
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
