import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/download_provider.dart';
import 'providers/call_provider.dart';
import 'services/websocket_service.dart';
import 'services/push_notification_service.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar timeago en español
  timeago.setLocaleMessages('es', timeago.EsMessages());
  
  // Solicitar permisos
  await _requestPermissions();
  
  // Inicializar Firebase y notificaciones
  await PushNotificationService.initialize();
  
  // Verificar sesión previa
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  // Conectar WebSocket si hay sesión
  if (token != null) {
    await WebSocketService.connect(token);
  }
  
  runApp(MyApp(initialToken: token));
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.storage,
    Permission.notification,
    Permission.microphone,
    Permission.camera,
    Permission.phone,
  ];
  
  await permissions.request();
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
        navigatorKey: PushNotificationService.navigatorKey,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFE53935),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE53935),
            secondary: Color(0xFFE53935),
            surface: Color(0xFF1A1A2E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D0D0D),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0D0D0D),
            selectedItemColor: Color(0xFFE53935),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
