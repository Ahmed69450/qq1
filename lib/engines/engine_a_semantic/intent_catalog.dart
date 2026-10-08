import '../../domain/entities/car_command.dart';

class CanonicalIntent {
  final CarActionType action;
  final List<String> triggerKeywords;
  final String confirmationResponse;
  final Map<String, dynamic> defaultParams;

  const CanonicalIntent({
    required this.action,
    required this.triggerKeywords,
    required this.confirmationResponse,
    this.defaultParams = const {},
  });
}

final List<CanonicalIntent> canonicalCatalog = [
  CanonicalIntent(
    action: CarActionType.airConditioner,
    triggerKeywords: ['تبريد', 'مكيف', 'حراره', 'سبلت', 'بروده', 'ايسي'],
    confirmationResponse: 'صار تدلل، شغلت التبريد',
  ),
  CanonicalIntent(
    action: CarActionType.windows,
    triggerKeywords: ['جامه', 'جامات', 'شباك', 'شبابيك', 'نافذه', 'نوافذ'],
    confirmationResponse: 'تم فتح النوافذ',
  ),
  CanonicalIntent(
    action: CarActionType.sunroof,
    triggerKeywords: ['فتحه', 'سقف', 'بانوراما'],
    confirmationResponse: 'تم تحريك فتحة السقف',
  ),
  CanonicalIntent(
    action: CarActionType.seats,
    triggerKeywords: ['كشن', 'كشنات', 'مقعد', 'مقاعد', 'تدفئه', 'مساج'],
    confirmationResponse: 'تم تشغيل تدفئة المقاعد',
  ),
];
