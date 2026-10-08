import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/voice_state.dart';
import 'package:offline_car_assistant/presentation/hud/bottom_capsule_overlay.dart';

void main() {
  testWidgets('BottomCapsuleOverlay renders voice state and text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BottomCapsuleOverlay(
            voiceState: VoiceState.listening,
            recognizedText: 'شغل التبريد',
          ),
        ),
      ),
    );

    expect(find.text('شغل التبريد'), findsOneWidget);
    expect(find.byType(BottomCapsuleOverlay), findsOneWidget);
  });
}
