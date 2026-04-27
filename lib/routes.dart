import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/call/audio_call_screen.dart';
import 'screens/users_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/upload_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String videoPlayer = '/video';
  static const String conversation = '/conversation';
  static const String audioCall = '/call';
  static const String users = '/users';
  static const String downloads = '/downloads';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String upload = '/upload';
  
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    users: (context) => const UsersScreen(),
    downloads: (context) => const DownloadsScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    upload: (context) => const UploadScreen(),
    audioCall: (context) => const AudioCallScreen(),
  };
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case videoPlayer:
        final video = settings.arguments;
        if (video != null) {
          return MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(video: video as dynamic),
          );
        }
        return null;
        
      case conversation:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => ConversationScreen(
              chatId: args['chatId'],
              otherUserId: args['otherUserId'],
              otherUsername: args['otherUsername'],
              otherAvatar: args['otherAvatar'],
            ),
          );
        }
        return null;
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
