import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/user_fact.dart';
import 'package:offline_car_assistant/engines/engine_b_llm/prompt_builder.dart';

void main() {
  test('constructs system prompt with Arabic dialect rules and context', () {
    final prompt = PromptBuilder.buildLlmPrompt(
      userQuery: 'وين أقرب محطة؟',
      foregroundApp: 'com.google.android.apps.maps',
      screenText: 'شارع فلسطين - بغداد',
      location: 'بغداد، العراق',
      facts: [
        UserFact(category: 'preference', key: 'fuel_type', value: 'بنزين محسن'),
      ],
    );

    expect(prompt, contains('أنت مساعد ذكي مدمج داخل شاشة سيارة BYD'));
    expect(prompt, contains('com.google.android.apps.maps'));
    expect(prompt, contains('شارع فلسطين - بغداد'));
    expect(prompt, contains('بنزين محسن'));
    expect(prompt, contains('وين أقرب محطة؟'));
  });
}
