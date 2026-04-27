import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import '../screens/call/audio_call_screen.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void handleIncomingCall(BuildContext context, String callerId, String callerName, String? callerAvatar) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.receiveCall(callerId, callerName, callerAvatar);
    
    // Mostrar overlay de llamada entrante
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE53935),
                  child: Text(
                    callerName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Llamada de $callerName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rechazar
                    GestureDetector(
                      onTap: () {
                        callProvider.rejectCall();
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Aceptar
                    GestureDetector(
                      onTap: () {
                        callProvider.acceptCall();
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AudioCallScreen()),
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  static void showPushNotification(String title, String body) {
    // Implementar notificaciones push locales
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
