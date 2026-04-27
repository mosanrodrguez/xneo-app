import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService {
  static RTCPeerConnection? _peerConnection;
  static MediaStream? _localStream;
  static MediaStream? _remoteStream;
  static RTCVideoRenderer? _localRenderer;
  static RTCVideoRenderer? _remoteRenderer;
  static StreamController<Map<String, dynamic>>? _callEventController;
  static bool _isInCall = false;

  static Stream<Map<String, dynamic>>? get callEvents => _callEventController?.stream;
  static bool get isInCall => _isInCall;
  static MediaStream? get localStream => _localStream;
  static MediaStream? get remoteStream => _remoteStream;

  static final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  /// Inicializar llamada
  static Future<void> startCall({
    required String roomId,
    required bool isVideo,
    required bool isCaller,
  }) async {
    _callEventController = StreamController<Map<String, dynamic>>.broadcast();
    _isInCall = true;
    
    // Crear peer connection
    _peerConnection = await createPeerConnection(_iceServers);
    
    // Obtener medios locales
    if (isVideo) {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      });
    } else {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
    }
    
    // Agregar stream local
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    
    // Escuchar tracks remotos
    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _callEventController?.add({'type': 'remote_stream'});
    };
    
    // Escuchar candidatos ICE
    _peerConnection!.onIceCandidate = (candidate) {
      WebSocketService.sendCallSignal(roomId, 'ice_candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };
    
    // Escuchar cambios de estado
    _peerConnection!.onConnectionState = (state) {
      _callEventController?.add({
        'type': 'connection_state',
        'state': state.name,
      });
    };
    
    if (isCaller) {
      // Crear oferta
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      WebSocketService.sendCallSignal(roomId, 'offer', {
        'sdp': offer.sdp,
      });
    }
    
    // Escuchar señales del WebSocket
    WebSocketService.notificationStream?.listen((message) async {
      if (message['type'] == 'call_signal') {
        await _handleSignal(message['signalType'], message['data']);
      }
    });
  }

  /// Manejar señales de WebRTC
  static Future<void> _handleSignal(String type, Map<String, dynamic>? data) async {
    if (_peerConnection == null || data == null) return;
    
    switch (type) {
      case 'offer':
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], 'offer'),
        );
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        break;
        
      case 'answer':
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], 'answer'),
        );
        break;
        
      case 'ice_candidate':
        if (data!['candidate'] != null) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
        break;
    }
  }

  /// Activar/desactivar micrófono
  static void toggleMic() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  /// Activar/desactivar cámara
  static void toggleCamera() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
    }
  }

  /// Voltear cámara
  static Future<void> flipCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await videoTrack.switchCamera();
    }
  }

  /// Finalizar llamada
  static Future<void> endCall() async {
    _isInCall = false;
    
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream = null;
    }
    
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    
    _remoteStream = null;
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _callEventController?.close();
  }
}
