enum CarActionType {
  airConditioner,
  windows,
  sunroof,
  seats,
  media,
  unknown,
}

class CarCommand {
  final CarActionType action;
  final String zone;
  final dynamic value;
  final String rawIntent;

  const CarCommand({
    required this.action,
    this.zone = 'all',
    this.value,
    required this.rawIntent,
  });

  Map<String, dynamic> toMap() => {
    'action': action.name,
    'zone': zone,
    'value': value,
    'rawIntent': rawIntent,
  };
}
