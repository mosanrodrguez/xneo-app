import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/download_task.dart';

class DownloadProvider extends ChangeNotifier {
  List<DownloadTask> _downloads = [];
  String _downloadPath = '';
  bool _wifiOnly = false;
  int _maxSimultaneous = 3;
  final Map<String, http.Client> _activeClients = {};

  List<DownloadTask> get downloads => _downloads;
  String get downloadPath => _downloadPath;
  bool get wifiOnly => _wifiOnly;
  int get maxSimultaneous => _maxSimultaneous;

  DownloadProvider() {
    _initDownloadPath();
  }

  Future<void> _initDownloadPath() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;
    
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      _downloadPath = '${dir.path}/XNEO';
      final xneoDir = Directory(_downloadPath);
      if (!await xneoDir.exists()) {
        await xneoDir.create(recursive: true);
      }
    }
  }

  Future<void> addDownload(String videoId, String title, String url, String? thumbnail) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    // Verificar si ya existe
    if (_downloads.any((d) => d.videoId == videoId)) return;

    final download = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      videoId: videoId,
      title: title,
      thumbnail: thumbnail,
      url: url,
      status: DownloadStatus.pending,
    );

    _downloads.add(download);
    notifyListeners();
    _startDownload(download);
  }

  Future<void> _startDownload(DownloadTask download) async {
    final filePath = '$_downloadPath/${download.title}.mp4';
    
    try {
      final client = http.Client();
      _activeClients[download.id] = client;
      
      final request = http.Request('GET', Uri.parse(download.url));
      final response = await client.send(request);
      
      final totalSize = response.contentLength ?? 0;
      final file = File(filePath);
      final sink = file.openWrite();
      
      int downloadedSize = 0;
      final startTime = DateTime.now();
      
      await for (final chunk in response.stream) {
        downloadedSize += chunk.length;
        sink.add(chunk);
        
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speed = elapsed > 0 ? (downloadedSize / elapsed) / 1048576 : 0.0;
        final progress = totalSize > 0 ? ((downloadedSize / totalSize) * 100).round() : 0;
        
        final index = _downloads.indexWhere((d) => d.id == download.id);
        if (index != -1) {
          _downloads[index] = download.copyWith(
            totalSize: totalSize,
            downloadedSize: downloadedSize,
            speed: speed,
            progress: progress,
            status: DownloadStatus.downloading,
            filePath: filePath,
          );
          notifyListeners();
        }
      }
      
      await sink.flush();
      await sink.close();
      _activeClients.remove(download.id);
      
      final index = _downloads.indexWhere((d) => d.id == download.id);
      if (index != -1) {
        _downloads[index] = download.copyWith(
          status: DownloadStatus.completed,
          progress: 100,
          filePath: filePath,
        );
        notifyListeners();
      }
    } catch (e) {
      final index = _downloads.indexWhere((d) => d.id == download.id);
      if (index != -1) {
        _downloads[index] = download.copyWith(status: DownloadStatus.failed);
        notifyListeners();
      }
    }
  }

  void pauseDownload(String downloadId) {
    _activeClients[downloadId]?.close();
    _activeClients.remove(downloadId);
    final index = _downloads.indexWhere((d) => d.id == downloadId);
    if (index != -1) {
      _downloads[index] = _downloads[index].copyWith(status: DownloadStatus.paused);
      notifyListeners();
    }
  }

  Future<void> resumeDownload(String downloadId) async {
    final index = _downloads.indexWhere((d) => d.id == downloadId);
    if (index != -1) {
      await _startDownload(_downloads[index]);
    }
  }

  void removeDownload(String downloadId) {
    _activeClients[downloadId]?.close();
    _activeClients.remove(downloadId);
    _downloads.removeWhere((d) => d.id == downloadId);
    notifyListeners();
  }

  void setDownloadPath(String path) {
    _downloadPath = path;
    notifyListeners();
  }

  void setWifiOnly(bool value) {
    _wifiOnly = value;
    notifyListeners();
  }

  void setMaxSimultaneous(int value) {
    _maxSimultaneous = value;
    notifyListeners();
  }
}
