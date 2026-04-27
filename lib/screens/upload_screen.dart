import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedVideo;
  String _title = '';
  String _description = '';
  String _category = 'Hetero';
  bool _isUploading = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _categories = ['Hetero', 'Bi', 'Gay', 'Trans'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedVideo = File(result.files.single.path!));
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un video'), backgroundColor: Colors.red));
      return;
    }
    if (_title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un título'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isUploading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final error = await videoProvider.uploadVideo(
      token: auth.token!,
      filePath: _selectedVideo!.path,
      title: _title.trim(),
      description: _description.trim(),
      category: _category,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $error'), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Video subido correctamente'), backgroundColor: Colors.green));
      setState(() { _selectedVideo = null; _title = ''; _description = ''; _category = 'Hetero'; });
      _titleController.clear();
      _descController.clear();
    }
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(title: const Text('Subir Video'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: Container(
                height: 200,
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
                child: _selectedVideo != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.video_file, size: 60, color: Color(0xFFE53935)), const SizedBox(height: 8), Text(_selectedVideo!.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 12))]))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cloud_upload_outlined, size: 50, color: Color(0xFFE53935)), const SizedBox(height: 8), Text('Toca para seleccionar', style: TextStyle(color: Colors.grey[400]))]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, onChanged: (v) => _title = v, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Título *', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: _descController, onChanged: (v) => _description = v, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Descripción (opcional)', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: const Text('Categoría:', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _categories.map((c) => ChoiceChip(label: Text(c), selected: _category == c, selectedColor: const Color(0xFFE53935), backgroundColor: const Color(0xFF2A2A3E), labelStyle: TextStyle(color: _category == c ? Colors.white : Colors.grey), onSelected: _isUploading ? null : (_) => setState(() => _category = c))).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isUploading ? null : _uploadVideo, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)), child: _isUploading ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 12), Text('Subiendo...')]) : const Text('Subir Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}
