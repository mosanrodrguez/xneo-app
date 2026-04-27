import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/call_provider.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  Timer? _timer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      if (callProvider.state == CallState.inProgress) {
        setState(() => _callDuration += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getStatusText(CallState state) {
    switch (state) {
      case CallState.calling:
        return 'Llamando...';
      case CallState.ringing:
        return 'Timbrando...';
      case CallState.connecting:
        return 'Conectando...';
      case CallState.inProgress:
        return 'En curso';
      case CallState.ended:
        return 'Finalizada';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Avatar del usuario
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE53935), width: 3),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE53935),
                child: Text(
                  (callProvider.callerName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Nombre del usuario
            Text(
              callProvider.callerName ?? 'Usuario',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Estado de la llamada
            Text(
              callProvider.state == CallState.inProgress
                  ? _formatDuration(_callDuration)
                  : _getStatusText(callProvider.state),
              style: TextStyle(
                fontSize: 16,
                color: callProvider.state == CallState.inProgress ? Colors.green : Colors.grey[400],
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Botones de control
            if (callProvider.state == CallState.inProgress)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallButton(
                      icon: callProvider.micEnabled ? Icons.mic : Icons.mic_off,
                      color: callProvider.micEnabled ? Colors.white : Colors.red,
                      backgroundColor: Colors.grey[800]!,
                      label: callProvider.micEnabled ? 'Micrófono' : 'Silenciado',
                      onPressed: () => callProvider.toggleMic(),
                    ),
                    _buildCallButton(
                      icon: callProvider.cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      color: callProvider.cameraEnabled ? Colors.white : Colors.red,
                      backgroundColor: Colors.grey[800]!,
                      label: callProvider.cameraEnabled ? 'Cámara' : 'Cámara apagada',
                      onPressed: () => callProvider.toggleCamera(),
                    ),
                  ],
                ),
              ),
            
            if (callProvider.state == CallState.inProgress && callProvider.cameraEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildCallButton(
                  icon: Icons.flip_camera_android,
                  color: Colors.white,
                  backgroundColor: Colors.grey[800]!,
                  label: 'Voltear',
                  onPressed: () {},
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Botón de finalizar
            _buildCallButton(
              icon: Icons.call_end,
              color: Colors.white,
              backgroundColor: const Color(0xFFE53935),
              label: 'Finalizar',
              onPressed: () {
                callProvider.endCall();
                Navigator.pop(context);
              },
              isLarge: true,
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String label,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: isLarge ? 70 : 60,
            height: isLarge ? 70 : 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}
