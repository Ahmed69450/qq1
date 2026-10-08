import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';
import 'package:offline_car_assistant/domain/entities/intent_match.dart';
import 'package:offline_car_assistant/domain/entities/user_fact.dart';

void main() {
  test('CarCommand should instantiate correctly with parameters', () {
    final cmd = CarCommand(
      action: CarActionType.airConditioner,
      zone: 'driver',
      value: 22,
      rawIntent: 'com.byd.intent.action.AC_CONTROL',
    );
    expect(cmd.action, equals(CarActionType.airConditioner));
    expect(cmd.value, equals(22));
    expect(cmd.toMap()['action'], equals('airConditioner'));
  });

  test('IntentMatch should properly calculate isConfident', () {
    final match = IntentMatch(
      action: CarActionType.windows,
      confidence: 0.85,
      spokenConfirmation: 'تم فتح النوافذ',
    );
    expect(match.isConfident(0.70), isTrue);

    final lowMatch = IntentMatch(
      action: CarActionType.unknown,
      confidence: 0.45,
      spokenConfirmation: '',
    );
    expect(lowMatch.isConfident(0.70), isFalse);
  });

  test('UserFact serialization and deserialization', () {
    final fact = UserFact(
      id: 1,
      category: 'climate',
      key: 'preferred_temp',
      value: '22',
      confidence: 0.9,
    );
    final map = fact.toMap();
    final reconstructed = UserFact.fromMap(map);
    expect(reconstructed.key, equals('preferred_temp'));
    expect(reconstructed.value, equals('22'));
  });
}
