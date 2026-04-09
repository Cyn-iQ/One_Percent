enum PrimaryAttributeType {
  strength,
  knowledge,
  virtue,
  social,
  skill,
  spirit,
}

extension PrimaryAttributeTypeX on PrimaryAttributeType {
  String get key {
    switch (this) {
      case PrimaryAttributeType.strength:
        return 'strength';
      case PrimaryAttributeType.knowledge:
        return 'knowledge';
      case PrimaryAttributeType.virtue:
        return 'virtue';
      case PrimaryAttributeType.social:
        return 'social';
      case PrimaryAttributeType.skill:
        return 'skill';
      case PrimaryAttributeType.spirit:
        return 'spirit';
    }
  }

  String get label {
    switch (this) {
      case PrimaryAttributeType.strength:
        return '力量';
      case PrimaryAttributeType.knowledge:
        return '知识';
      case PrimaryAttributeType.virtue:
        return '品德';
      case PrimaryAttributeType.social:
        return '社交';
      case PrimaryAttributeType.skill:
        return '技能';
      case PrimaryAttributeType.spirit:
        return '精神';
    }
  }

  static PrimaryAttributeType fromKey(String key) {
    return PrimaryAttributeType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PrimaryAttributeType.strength,
    );
  }
}

class PrimaryAttribute {
  static const double baseScore = 10.0;

  final PrimaryAttributeType type;
  final double secondaryContribution;

  const PrimaryAttribute({
    required this.type,
    required this.secondaryContribution,
  });

  double get currentScore => baseScore + secondaryContribution;

  PrimaryAttribute copyWith({
    PrimaryAttributeType? type,
    double? secondaryContribution,
  }) {
    return PrimaryAttribute(
      type: type ?? this.type,
      secondaryContribution:
          secondaryContribution ?? this.secondaryContribution,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.key,
      'secondaryContribution': secondaryContribution,
    };
  }

  factory PrimaryAttribute.fromMap(Map<String, dynamic> map) {
    return PrimaryAttribute(
      type: PrimaryAttributeTypeX.fromKey(map['type'] as String),
      secondaryContribution:
          (map['secondaryContribution'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
