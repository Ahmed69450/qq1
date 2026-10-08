import '../constants/arabic_stopwords.dart';

class ArabicNormalizer {
  static final RegExp _tashkeel = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
  static final RegExp _alef = RegExp(r'[إأآ]');
  static final RegExp _taaMarbuta = RegExp(r'ة');
  static final RegExp _allowedChars = RegExp(r'[^\u0600-\u06FF0-9\s]');
  static final RegExp _multipleSpaces = RegExp(r'\s+');

  static String normalize(String text) {
    if (text.isEmpty) return '';
    var result = text;
    result = result.replaceAll(_tashkeel, '');
    result = result.replaceAll(_alef, 'ا');
    result = result.replaceAll(_taaMarbuta, 'ه');
    result = result.replaceAll('ى', 'ي');
    result = result.replaceAll(_allowedChars, ' ');
    result = result.replaceAll(_multipleSpaces, ' ').trim();
    return result;
  }

  static List<String> tokenize(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return [];
    return normalized.split(' ');
  }

  static List<String> tokenizeWithoutStopwords(String text) {
    final tokens = tokenize(text);
    return tokens.where((t) => !arabicIraqiStopwords.contains(t)).toList();
  }
}
