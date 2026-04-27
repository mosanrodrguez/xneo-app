import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../models/download_task.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Descargas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de configuración
          if (_showSettings)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A2E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuración de descargas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Ubicación
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder, color: Color(0xFFE53935)),
                    title: const Text('Ubicación', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      downloadProvider.downloadPath.split('/').last,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      // Abrir selector de carpeta
                    },
                  ),
                  
                  // Solo WiFi
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo descargar por WiFi', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Ahorra datos móviles', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: downloadProvider.wifiOnly,
                    activeColor: const Color(0xFFE53935),
                    onChanged: (value) => downloadProvider.setWifiOnly(value),
                  ),
                  
                  // Descargas simultáneas
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.downloading, color: Color(0xFFE53935)),
                    title: const Text('Descargas simultáneas', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${downloadProvider.maxSimultaneous} videos al mismo tiempo',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.grey),
                          onPressed: () {
                            if (downloadProvider.maxSimultaneous > 1) {
                              downloadProvider.setMaxSimultaneous(downloadProvider.maxSimultaneous - 1);
                            }
                          },
                        ),
                        Text(downloadProvider.maxSimultaneous.toString(), style: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.grey),
                          onPressed: () {
                            if (downloadProvider.maxSimultaneous < 5) {
                              downloadProvider.setMaxSimultaneous(downloadProvider.maxSimultaneous + 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de descargas
          Expanded(
            child: downloadProvider.downloads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No hay descargas activas', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          'Descarga videos desde XNEO para verlos sin conexión',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: downloadProvider.downloads.length,
                    itemBuilder: (context, index) {
                      final download = downloadProvider.downloads[index];
                      return _DownloadCard(download: download);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadTask download;

  const _DownloadCard({required this.download});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Miniatura
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.video_library, color: Colors.grey, size: 30),
                ),
                const SizedBox(width: 12),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(download.downloadedSize / 1048576).toStringAsFixed(1)} MB / ${(download.totalSize / 1048576).toStringAsFixed(1)} MB',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${download.speed.toStringAsFixed(1)} MB/s',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${download.progress}%',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Barra de progreso
                      LinearProgressIndicator(
                        value: download.progress / 100,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                
                // Botón eliminar
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () => downloadProvider.removeDownload(download.id),
                ),
              ],
            ),
          ),
          
          // Botón pausar/reanudar
          if (download.status == DownloadStatus.downloading || download.status == DownloadStatus.paused)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2A2A3E), width: 0.5)),
              ),
              child: TextButton.icon(
                onPressed: () {
                  if (download.status == DownloadStatus.downloading) {
                    downloadProvider.pauseDownload(download.id);
                  } else {
                    downloadProvider.resumeDownload(download.id);
                  }
                },
                icon: Icon(
                  download.status == DownloadStatus.downloading ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  download.status == DownloadStatus.downloading ? 'Pausar' : 'Reanudar',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
