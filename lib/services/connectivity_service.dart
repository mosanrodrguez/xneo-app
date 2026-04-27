import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isWifi = false;
  
  static bool get isWifi => _isWifi;
  
  static Future<bool> checkWifi() async {
    final result = await _connectivity.checkConnectivity();
    _isWifi = result.contains(ConnectivityResult.wifi);
    return _isWifi;
  }
  
  static void startMonitoring(Function(bool) onChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isWifi = results.contains(ConnectivityResult.wifi);
      _isWifi = isWifi;
      onChanged(isWifi);
    });
  }
  
  static void stopMonitoring() {
    _subscription?.cancel();
  }
}
