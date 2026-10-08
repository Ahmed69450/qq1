import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/core/utils/tts_sanitizer.dart';

void main() {
  test('strips Markdown formatting elements', () {
    final raw = '**تم تفعيل** التبريد بنجاح! ## التفاصيل: - حرارة 22';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, isNot(contains('**')));
    expect(clean, isNot(contains('##')));
    expect(clean, isNot(contains('-')));
  });

  test('strips emojis', () {
    final raw = 'صباح الخير 🚗❄️ تم ضبط الجو 👍';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, equals('صباح الخير تم ضبط الجو'));
  });

  test('converts symbols into Arabic spoken words', () {
    final raw = 'نسبة الشحن 85% والحرارة 24°C والسرعة 80km/h';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, contains('بالمئة'));
    expect(clean, contains('درجة مئوية'));
    expect(clean, contains('كيلومتر بالساعة'));
  });

  test('converts basic numbers into spoken Arabic words', () {
    final raw = 'الحرارة 22';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, contains('اثنين وعشرين'));
  });
}
