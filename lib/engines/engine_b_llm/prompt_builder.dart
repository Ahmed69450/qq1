import '../../domain/entities/user_fact.dart';

class PromptBuilder {
  static String buildLlmPrompt({
    required String userQuery,
    String? foregroundApp,
    String? screenText,
    String? location,
    List<UserFact> facts = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>system');
    buffer.writeln('أنت مساعد ذكي مدمج داخل شاشة سيارة BYD.');
    buffer.writeln('القواعد:');
    buffer.writeln('1. أجب باختصار شديد (جملة أو جملتان) وباللهجة العراقية/العربية البسيطة.');
    buffer.writeln('2. تجنب علامات الماركداون والرموز التعبيرية كلياً لأن الرد سيتم نطقه صوتياً.');

    if (foregroundApp != null && foregroundApp.isNotEmpty) {
      buffer.writeln('التطبيق النشط حالياً: $foregroundApp');
    }
    if (screenText != null && screenText.isNotEmpty) {
      buffer.writeln('محتوى الشاشة: $screenText');
    }
    if (location != null && location.isNotEmpty) {
      buffer.writeln('الموقع الحالي: $location');
    }
    if (facts.isNotEmpty) {
      buffer.writeln('معلومات السائق المحفوظة:');
      for (final f in facts) {
        buffer.writeln('- ${f.key}: ${f.value}');
      }
    }
    buffer.writeln('<|im_end|>');
    buffer.writeln('<|im_start|>user');
    buffer.writeln(userQuery);
    buffer.writeln('<|im_end|>');
    buffer.writeln('<|im_start|>assistant');

    return buffer.toString();
  }
}
