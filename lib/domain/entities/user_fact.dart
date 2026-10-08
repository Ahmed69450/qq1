class UserFact {
  final int? id;
  final String category;
  final String key;
  final String value;
  final double confidence;
  final int updatedAt;

  UserFact({
    this.id,
    required this.category,
    required this.key,
    required this.value,
    this.confidence = 1.0,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'fact_key': key,
    'fact_value': value,
    'confidence': confidence,
    'updated_at': updatedAt,
  };

  factory UserFact.fromMap(Map<String, dynamic> map) => UserFact(
    id: map['id'] as int?,
    category: map['category'] as String,
    key: map['fact_key'] as String,
    value: map['fact_value'] as String,
    confidence: (map['confidence'] as num).toDouble(),
    updatedAt: map['updated_at'] as int,
  );
}
