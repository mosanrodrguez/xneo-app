import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import '../screens/call/audio_call_screen.dart';

const API_URL = 'https://xneo-web.onrender.com';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Inicializa Firebase y notificaciones
  static Future<void> initialize() async {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Configurar notificaciones locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    
    // Solicitar permisos
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('Permiso de notificaciones: ${settings.authorizationStatus}');
    
    // Obtener token FCM
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');
    
    // Registrar token en el backend
    if (fcmToken != null) {
      await _registerFCMToken(fcmToken);
    }
    
    // Escuchar tokens renovados
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _registerFCMToken(newToken);
    });
    
    // Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Manejar cuando se toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Manejar notificación que abrió la app desde terminada
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _registerFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');
    
    if (authToken == null) return;
    
    try {
      await http.post(
        Uri.parse('$API_URL/api/notifications/register'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fcmToken': token,
          'platform': 'android',
        }),
      );
    } catch (e) {
      print('Error registrando FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final title = message.notification?.title ?? 'XNEO';
    final body = message.notification?.body ?? '';
    
    // Mostrar notificación local
    _showLocalNotification(title, body);
    
    // Manejar tipos específicos
    switch (type) {
      case 'incoming_call':
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showIncomingCallDialog(context, data);
        }
        break;
      case 'new_message':
        // Actualizar chat si está abierto
        break;
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'new_message':
        final chatId = data['chatId'];
        // Navegar al chat
        if (chatId != null && navigatorKey.currentContext != null) {
          // Implementar navegación al chat específico
        }
        break;
      case 'new_video':
        final videoId = data['videoId'];
        // Navegar al video
        break;
      case 'incoming_call':
        // Ir a la pantalla de llamada
        break;
    }
  }

  static Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'xneo_channel',
      'XNEO Notificaciones',
      channelDescription: 'Notificaciones de XNEO',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE53935),
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static void _showIncomingCallDialog(BuildContext context, Map<String, dynamic> data) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final callerId = data['callerId'] ?? '';
    final callerName = data['callerName'] ?? 'Usuario';
    final callerAvatar = data['callerAvatar'];
    
    callProvider.receiveCall(callerId, callerName, callerAvatar);
    
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
                  radius: 45,
                  backgroundColor: const Color(0xFFE53935),
                  child: Text(
                    callerName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
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

  /// Cerrar sesión - eliminar token FCM
  static Future<void> unregisterToken() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');
    
    if (authToken != null) {
      try {
        await http.delete(
          Uri.parse('$API_URL/api/notifications/unregister'),
          headers: {'Authorization': 'Bearer $authToken'},
        );
      } catch (e) {
        print('Error eliminando FCM token: $e');
      }
    }
  }
}
