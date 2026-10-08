import 'package:flutter/material.dart';
import 'domain/entities/voice_state.dart';
import 'presentation/hud/bottom_capsule_overlay.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: BottomCapsuleOverlay(
          voiceState: VoiceState.listening,
          recognizedText: 'جاهز للاستماع...',
        ),
      ),
    ),
  );
}
