import 'car_command.dart';

class IntentMatch {
  final CarActionType action;
  final double confidence;
  final String spokenConfirmation;
  final Map<String, dynamic> parameters;

  const IntentMatch({
    required this.action,
    required this.confidence,
    required this.spokenConfirmation,
    this.parameters = const {},
  });

  bool isConfident(double threshold) => confidence >= threshold;
}
