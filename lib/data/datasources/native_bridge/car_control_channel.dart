import 'package:flutter/services.dart';
import '../../../domain/entities/car_command.dart';

class CarControlChannel {
  static const MethodChannel _channel = MethodChannel('com.byd.assistant/car_control');

  Future<bool> dispatchCommand(CarCommand command) async {
    try {
      final res = await _channel.invokeMethod<Map>('dispatchCarCommand', command.toMap());
      return res != null;
    } on PlatformException {
      return false;
    }
  }
}
