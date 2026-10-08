import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/data/datasources/native_bridge/car_control_channel.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CarControlChannel channel;
  final List<MethodCall> log = [];

  setUp(() {
    channel = CarControlChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.byd.assistant/car_control'), (call) async {
      log.add(call);
      return {'status': 'dispatched_simulated'};
    });
  });

  tearDown(() {
    log.clear();
  });

  test('dispatches car command to platform channel', () async {
    final cmd = CarCommand(
      action: CarActionType.airConditioner,
      zone: 'driver',
      value: 20,
      rawIntent: 'com.byd.intent.action.AC_CONTROL',
    );
    final result = await channel.dispatchCommand(cmd);
    expect(result, isTrue);
    expect(log.length, equals(1));
    expect(log.first.method, equals('dispatchCarCommand'));
    expect(log.first.arguments['action'], equals('airConditioner'));
  });
}
