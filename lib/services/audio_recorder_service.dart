import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloudinary_service.dart';

class AudioRecorderService {
  static final AudioRecorder _recorder = AudioRecorder();
  static StreamSubscription<RecordState>? _stateSubscription;
  static StreamController<Duration>? _durationController;
  static bool _isRecording = false;
  static String? _currentFilePath;
  static DateTime? _startTime;

  static bool get isRecording => _isRecording;
  static Stream<Duration>? get durationStream => _durationController?.stream;

  /// Iniciar grabación
  static Future<void> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      _currentFilePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentFilePath!,
      );
      
      _isRecording = true;
      _startTime = DateTime.now();
      
      _durationController = StreamController<Duration>();
      
      // Emitir duración cada 100ms
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        final duration = DateTime.now().difference(_startTime!);
        _durationController?.add(duration);
      });
      
      _stateSubscription = _recorder.onStateChanged().listen((state) {
        if (state == RecordState.stop) {
          _isRecording = false;
        }
      });
      
    } catch (e) {
      print('Error iniciando grabación: $e');
    }
  }

  /// Detener grabación y obtener archivo
  static Future<Map<String, dynamic>?> stopRecording() async {
    if (!_isRecording) return null;
    
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _durationController?.close();
      _stateSubscription?.cancel();
      
      if (path != null && _currentFilePath != null) {
        final file = File(_currentFilePath!);
        final sizeInBytes = await file.length();
        final duration = DateTime.now().difference(_startTime!);
        
        // Subir a Cloudinary
        final result = await CloudinaryService.uploadImage(_currentFilePath!);
        
        return {
          'filePath': _currentFilePath,
          'url': result,
          'duration': duration.inSeconds,
          'size': sizeInBytes,
        };
      }
    } catch (e) {
      print('Error deteniendo grabación: $e');
    }
    
    return null;
  }

  /// Cancelar grabación
  static Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
      _durationController?.close();
      _stateSubscription?.cancel();
      
      // Eliminar archivo
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  /// Obtener duración actual
  static Duration getCurrentDuration() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }
}
