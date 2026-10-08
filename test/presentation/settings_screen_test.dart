import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/presentation/settings/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders header and model options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('إعدادات المساعد الصوتي'), findsOneWidget);
    expect(find.text('إدارة النماذج الذكية (LLM & ONNX)'), findsOneWidget);
  });
}
