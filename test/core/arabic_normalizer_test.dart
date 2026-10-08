import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/core/utils/arabic_normalizer.dart';

void main() {
  test('normalizes Alef variants to bare Alef', () {
    expect(ArabicNormalizer.normalize('أحمد إبراهيم آمنة'), equals('احمد ابراهيم امنه'));
  });

  test('normalizes Taa Marbuta to Haa', () {
    expect(ArabicNormalizer.normalize('سيارة جميلة'), equals('سياره جميله'));
  });

  test('strips Arabic diacritics (Tashkeel)', () {
    expect(ArabicNormalizer.normalize('شَغِّلْ التَّبْرِيدَ'), equals('شغل التبريد'));
  });

  test('removes non-Arabic and non-digit characters', () {
    expect(ArabicNormalizer.normalize('شغل المكيف! #100%'), equals('شغل المكيف 100'));
  });

  test('removes dialect stopwords correctly', () {
    final tokens = ArabicNormalizer.tokenizeWithoutStopwords('شنو شغل لي المكيف بالسيارة');
    expect(tokens, contains('شغل'));
    expect(tokens, contains('المكيف'));
    expect(tokens, isNot(contains('شنو')));
    expect(tokens, isNot(contains('لي')));
  });
}
