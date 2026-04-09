import 'primary_attribute.dart';

class ScoreRecord {
  final int? id;
  final int secondaryAttributeId;
  final PrimaryAttributeType primaryType;
  final String secondaryNameSnapshot;
  final double delta;
  final String? note;
  final DateTime createdAt;

  const ScoreRecord({
    this.id,
    required this.secondaryAttributeId,
    required this.primaryType,
    required this.secondaryNameSnapshot,
    required this.delta,
    this.note,
    required this.createdAt,
  });

  bool get isPositive => delta > 0;
  bool get isNegative => delta < 0;

  ScoreRecord copyWith({
    int? id,
    int? secondaryAttributeId,
    PrimaryAttributeType? primaryType,
    String? secondaryNameSnapshot,
    double? delta,
    String? note,
    DateTime? createdAt,
  }) {
    return ScoreRecord(
      id: id ?? this.id,
      secondaryAttributeId: secondaryAttributeId ?? this.secondaryAttributeId,
      primaryType: primaryType ?? this.primaryType,
      secondaryNameSnapshot:
          secondaryNameSnapshot ?? this.secondaryNameSnapshot,
      delta: delta ?? this.delta,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'secondaryAttributeId': secondaryAttributeId,
      'primaryType': primaryType.key,
      'secondaryNameSnapshot': secondaryNameSnapshot,
      'delta': delta,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScoreRecord.fromMap(Map<String, dynamic> map) {
    return ScoreRecord(
      id: map['id'] as int?,
      secondaryAttributeId: map['secondaryAttributeId'] as int,
      primaryType: PrimaryAttributeTypeX.fromKey(map['primaryType'] as String),
      secondaryNameSnapshot: map['secondaryNameSnapshot'] as String,
      delta: (map['delta'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}