import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import 'video_player_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedCategory = 'Hetero';
  bool _showCategoryPicker = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    await videoProvider.fetchUserVideos(auth.token!);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCategory = prefs.getString('category') ?? 'Hetero';
    });
  }

  Future<void> _changeCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category', category);
    setState(() {
      _selectedCategory = category;
      _showCategoryPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header del perfil
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Avatar grande centrado
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            // Subir imagen de perfil
                          }
                        },
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: const Color(0xFFE53935),
                          child: Text(
                            (auth.user?.username ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nombre de usuario
                    Text(
                      auth.user?.username ?? 'Usuario',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Info de perfil
                    Text(
                      auth.user?.role == 'admin' ? 'Administrador' : 'Usuario',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de categoría
                    GestureDetector(
                      onTap: () => setState(() => _showCategoryPicker = !_showCategoryPicker),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Categoría: $_selectedCategory',
                              style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFFE53935)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Panel de categorías
                    if (_showCategoryPicker)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildCategoryOption('Hetero', Icons.male),
                            _buildCategoryOption('Bi', Icons.people_outline),
                            _buildCategoryOption('Gay', Icons.people),
                            _buildCategoryOption('Trans', Icons.transgender),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Botón editar perfil
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[600]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Editar perfil', style: TextStyle(color: Colors.grey[300])),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divisor
                    Container(height: 1, color: const Color(0xFF2A2A3E)),
                    
                    // Sección mis videos
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mis Videos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Grid de videos del usuario
              if (videoProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                  )),
                )
              else if (videoProvider.userVideos.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.video_library_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No has subido videos aún', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = videoProvider.userVideos[index];
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
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    color: Colors.grey[900],
                                    child: video.thumbnail != null
                                        ? CachedNetworkImage(
                                            imageUrl: video.thumbnail!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.video_library, size: 40, color: Colors.grey),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.visibility, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(video.views.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.thumb_up, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(video.likes.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: videoProvider.userVideos.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _changeCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
