import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/download_provider.dart';
import 'providers/call_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Pedir TODOS los permisos necesarios
  await _requestAllPermissions();

  // 2. Inicializar Firebase SIN crashear
  await _initFirebaseSafely();

  // 3. Configurar notificaciones locales
  await _initLocalNotifications();

  // 4. Configurar timeago
  timeago.setLocaleMessages('es', timeago.EsMessages());

  // 5. Verificar sesión guardada
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  // 6. Iniciar app
  runApp(MyApp(initialToken: token));
}

Future<void> _requestAllPermissions() async {
  final permissions = [
    Permission.storage,
    Permission.camera,
    Permission.microphone,
    Permission.notification,
    Permission.photos,
    Permission.phone,
  ];

  for (var permission in permissions) {
    try {
      await permission.request();
    } catch (e) {
      print('Permiso ${permission.toString()}: $e');
    }
  }
}

Future<void> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
    final token = await FirebaseMessaging.instance.getToken();
    print('✅ Firebase OK - FCM Token: ${token?.substring(0, 10)}...');
    
    // Pedir permiso de notificaciones en Android 13+
    await FirebaseMessaging.instance.requestPermission();
  } catch (e) {
    print('⚠️ Firebase no disponible: $e');
    // La app sigue funcionando sin Firebase
  }
}

Future<void> _initLocalNotifications() async {
  try {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await FlutterLocalNotificationsPlugin().initialize(initSettings);
  } catch (e) {
    print('⚠️ Notificaciones locales no disponibles: $e');
  }
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(initialToken)),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp(
        title: 'XNEO',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFFE53935),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
