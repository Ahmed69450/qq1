import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';
import 'package:offline_car_assistant/engines/engine_a_semantic/semantic_router.dart';

void main() {
  late SemanticRouter router;

  setUp(() {
    router = SemanticRouter();
  });

  test('matches AC command with high confidence', () {
    final match = router.matchIntent('شغل التبريد فدوه');
    expect(match, isNotNull);
    expect(match!.action, equals(CarActionType.airConditioner));
    expect(match.confidence, greaterThanOrEqualTo(0.70));
    expect(match.spokenConfirmation, contains('التبريد'));
  });

  test('matches Window command with high confidence', () {
    final match = router.matchIntent('افتح الجامات او الشبابيك');
    expect(match, isNotNull);
    expect(match!.action, equals(CarActionType.windows));
    expect(match.confidence, greaterThanOrEqualTo(0.70));
  });

  test('returns null or low score for open conversational queries', () {
    final match = router.matchIntent('من هو مخترع السيارة الكهربائية؟');
    expect(match, isNull);
  });
}
