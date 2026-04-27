import 'package:flutter/material.dart';

enum CallState {
  idle,
  calling,
  ringing,
  connecting,
  inProgress,
  ended,
}

class CallProvider extends ChangeNotifier {
  CallState _state = CallState.idle;
  String? _callerName;
  String? _callerAvatar;
  String? _callerId;
  Duration _duration = Duration.zero;
  bool _micEnabled = true;
  bool _cameraEnabled = false;
  bool _incomingCall = false;

  CallState get state => _state;
  String? get callerName => _callerName;
  String? get callerAvatar => _callerAvatar;
  String? get callerId => _callerId;
  Duration get duration => _duration;
  bool get micEnabled => _micEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get incomingCall => _incomingCall;

  void startCall(String userId, String name, String? avatar) {
    _callerId = userId;
    _callerName = name;
    _callerAvatar = avatar;
    _state = CallState.calling;
    _incomingCall = false;
    notifyListeners();
  }

  void receiveCall(String userId, String name, String? avatar) {
    _callerId = userId;
    _callerName = name;
    _callerAvatar = avatar;
    _state = CallState.ringing;
    _incomingCall = true;
    notifyListeners();
  }

  void acceptCall() {
    _state = CallState.connecting;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _state = CallState.inProgress;
      notifyListeners();
    });
  }

  void rejectCall() {
    _state = CallState.ended;
    _incomingCall = false;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      _state = CallState.idle;
      notifyListeners();
    });
  }

  void toggleMic() {
    _micEnabled = !_micEnabled;
    notifyListeners();
  }

  void toggleCamera() {
    _cameraEnabled = !_cameraEnabled;
    notifyListeners();
  }

  void endCall() {
    _state = CallState.ended;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      _state = CallState.idle;
      _callerId = null;
      _callerName = null;
      _callerAvatar = null;
      _incomingCall = false;
      notifyListeners();
    });
  }
}
