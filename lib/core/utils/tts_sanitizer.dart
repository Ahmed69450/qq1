class TtsSanitizer {
  static final RegExp _markdown = RegExp(r'[*#_~`>\[\]\(\)\-]');
  static final RegExp _emojis = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );
  static final RegExp _spaces = RegExp(r'\s+');

  static final Map<int, String> _smallNumbers = {
    0: 'صفر', 1: 'واحد', 2: 'اثنين', 3: 'ثلاثة', 4: 'أربعة',
    5: 'خمسة', 6: 'ستة', 7: 'سبعة', 8: 'ثمانية', 9: 'تسعة',
    10: 'عشرة', 11: 'أحد عشر', 12: 'اثنا عشر', 13: 'ثلاثة عشر',
    14: 'أربعة عشر', 15: 'خمسة عشر', 16: 'ستة عشر', 17: 'سبعة عشر',
    18: 'ثمانية عشر', 19: 'تسعة عشر', 20: 'عشرين', 30: 'ثلاثين',
    40: 'أربعين', 50: 'خمسين', 60: 'ستين', 70: 'سبعين',
    80: 'ثمانين', 90: 'تسعين', 100: 'مئة',
  };

  static String numberToSpokenArabic(int number) {
    if (_smallNumbers.containsKey(number)) return _smallNumbers[number]!;
    if (number > 20 && number < 100) {
      final unit = number % 10;
      final tens = (number ~/ 10) * 10;
      if (unit == 0) return _smallNumbers[tens]!;
      return '${_smallNumbers[unit]} و${_smallNumbers[tens]}';
    }
    return number.toString();
  }

  static String sanitizeForSpeech(String text) {
    if (text.isEmpty) return '';
    var result = text;
    result = result.replaceAll(_markdown, ' ');
    result = result.replaceAll(_emojis, ' ');
    result = result.replaceAll('%', ' بالمئة ');
    result = result.replaceAll('°C', ' درجة مئوية ');
    result = result.replaceAll('C°', ' درجة مئوية ');
    result = result.replaceAll('km/h', ' كيلومتر بالساعة ');
    result = result.replaceAll('+', ' زائد ');

    // Convert 1-2 digit numbers to Arabic spoken words
    result = result.replaceAllMapped(RegExp(r'\b\d{1,2}\b'), (match) {
      final val = int.tryParse(match.group(0)!);
      return val != null ? ' ${numberToSpokenArabic(val)} ' : match.group(0)!;
    });

    result = result.replaceAll(_spaces, ' ').trim();
    return result;
  }
}
