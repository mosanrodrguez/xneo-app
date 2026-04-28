import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/download_provider.dart';
import 'providers/call_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar timeago
  timeago.setLocaleMessages('es', timeago.EsMessages());
  
  // Iniciar sin Firebase por ahora (evita crash)
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  runApp(MyApp(initialToken: token));
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
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFFE53935),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
