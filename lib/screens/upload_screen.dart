import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../services/cloudinary_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedVideo;
  File? _selectedThumbnail;
  String _title = '';
  String _description = '';
  String _category = 'Hetero';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  VideoPlayerController? _videoController;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _categories = ['Hetero', 'Bi', 'Gay', 'Trans'];
  final Map<String, IconData> _categoryIcons = {
    'Hetero': Icons.male,
    'Bi': Icons.people_outline,
    'Gay': Icons.people,
    'Trans': Icons.transgender,
  };

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
      });
      
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_selectedVideo!);
      await _videoController!.initialize();
      setState(() {});
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedThumbnail = File(image.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      _showError('Selecciona un video');
      return;
    }
    if (_title.isEmpty) {
      _showError('Ingresa un título');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Subir miniatura personalizada (si se seleccionó)
      String? thumbnailUrl;
      if (_selectedThumbnail != null) {
        thumbnailUrl = await CloudinaryService.uploadThumbnail(_selectedThumbnail!.path);
      }

      // 2. Subir video a Cloudinary
      final uploadResult = await CloudinaryService.uploadVideo(
        _selectedVideo!.path,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (uploadResult == null) {
        _showError('Error al subir el video');
        setState(() => _isUploading = false);
        return;
      }

      // 3. Guardar en el backend
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);

      final error = await videoProvider.uploadVideo(
        token: auth.token!,
        filePath: uploadResult['url'],
        title: _title.trim(),
        description: _description.trim().isEmpty ? null : _description.trim(),
        category: _category,
      );

      if (error != null) {
        _showError(error);
      } else {
        _showSuccess('¡Video subido correctamente!');
        _resetForm();
      }
    } catch (e) {
      _showError('Error inesperado: $e');
    }

    setState(() => _isUploading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedVideo = null;
      _selectedThumbnail = null;
      _title = '';
      _description = '';
      _category = 'Hetero';
      _uploadProgress = 0.0;
    });
    _titleController.clear();
    _descController.clear();
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Subir Video', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de video
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedVideo != null ? const Color(0xFFE53935) : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _selectedVideo != null && _videoController != null && _videoController!.value.isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: VideoPlayer(_videoController!),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _resetForm,
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 64),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 60, color: Color(0xFFE53935)),
                          const SizedBox(height: 12),
                          const Text('Seleccionar Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('MP4, MOV, AVI', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            TextField(
              controller: _titleController,
              onChanged: (v) => _title = v,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Título del video *',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Descripción
            TextField(
              controller: _descController,
              onChanged: (v) => _description = v,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Descripción (opcional)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Miniatura personalizada
            GestureDetector(
              onTap: _isUploading ? null : _pickThumbnail,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedThumbnail != null ? null : Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _selectedThumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(_selectedThumbnail!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Text('Miniatura personalizada', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Categoría
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE53935) : const Color(0xFF2A2A3E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_categoryIcons[cat], color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(cat, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Barra de progreso
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress / 100 : null,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                'Subiendo... ${_uploadProgress.toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
            
            // Botón de subir
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Subiendo...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text('Subir Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
