import 'package:flutter/material.dart';
import '../../domain/entities/voice_state.dart';
import 'wave_visualizer.dart';

class BottomCapsuleOverlay extends StatelessWidget {
  final VoiceState voiceState;
  final String recognizedText;
  final VoidCallback? onDismiss;

  const BottomCapsuleOverlay({
    super.key,
    required this.voiceState,
    required this.recognizedText,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xDD181818),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaveVisualizer(isListening: voiceState == VoiceState.listening),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                recognizedText.isEmpty ? 'المساعد يستمع...' : recognizedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
