import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService {
  static RTCPeerConnection? _peerConnection;
  static MediaStream? _localStream;
  static MediaStream? _remoteStream;
  static bool _isInCall = false;

  static bool get isInCall => _isInCall;
  static MediaStream? get localStream => _localStream;
  static MediaStream? get remoteStream => _remoteStream;

  // Servidores STUN/TURN gratuitos y públicos
  static final Map<String, dynamic> _iceServers = {
    'iceServers': [
      // STUN de Google (gratuito)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // STUN de Twilio (gratuito)
      {'urls': 'stun:global.stun.twilio.com:3478'},
      // TURN gratuito de Metered
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      // TURN gratuito de Cloudflare
      {
        'urls': 'turn:turn.cloudflare.com:3478',
        'username': 'free-turn',
        'credential': 'free'
      },
    ],
  };

  static Future<void> startCall({required bool isVideo}) async {
    _isInCall = true;
    
    _peerConnection = await createPeerConnection(_iceServers);
    
    // Obtener medios locales
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo,
    });
    
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    
    _peerConnection!.onIceCandidate = (candidate) {
      WebSocketService.sendMessage({
        'type': 'call_signal',
        'signalType': 'ice_candidate',
        'data': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    WebSocketService.sendMessage({
      'type': 'call_signal',
      'signalType': 'offer',
      'data': {'sdp': offer.sdp},
    });
  }

  static void toggleMic() {
    _localStream?.getAudioTracks().first.enabled = 
        !(_localStream?.getAudioTracks().first.enabled ?? true);
  }

  static void toggleCamera() {
    _localStream?.getVideoTracks().first.enabled = 
        !(_localStream?.getVideoTracks().first.enabled ?? true);
  }

  static Future<void> flipCamera() async {
    await _localStream?.getVideoTracks().first.switchCamera();
  }

  static Future<void> endCall() async {
    _isInCall = false;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
  }
}
