import 'primary_attribute.dart';

class DailySnapshot {
  final String date; // yyyy-MM-dd
  final double strengthScore;
  final double knowledgeScore;
  final double virtueScore;
  final double socialScore;
  final double skillScore;
  final double spiritScore;
  final double totalScore;
  final double? changeValue;
  final double? changePercentage;

  const DailySnapshot({
    required this.date,
    required this.strengthScore,
    required this.knowledgeScore,
    required this.virtueScore,
    required this.socialScore,
    required this.skillScore,
    required this.spiritScore,
    required this.totalScore,
    this.changeValue,
    this.changePercentage,
  });

  double scoreOf(PrimaryAttributeType type) {
    switch (type) {
      case PrimaryAttributeType.strength:
        return strengthScore;
      case PrimaryAttributeType.knowledge:
        return knowledgeScore;
      case PrimaryAttributeType.virtue:
        return virtueScore;
      case PrimaryAttributeType.social:
        return socialScore;
      case PrimaryAttributeType.skill:
        return skillScore;
      case PrimaryAttributeType.spirit:
        return spiritScore;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'strengthScore': strengthScore,
      'knowledgeScore': knowledgeScore,
      'virtueScore': virtueScore,
      'socialScore': socialScore,
      'skillScore': skillScore,
      'spiritScore': spiritScore,
      'totalScore': totalScore,
      'changeValue': changeValue,
      'changePercentage': changePercentage,
    };
  }

  factory DailySnapshot.fromMap(Map<String, dynamic> map) {
    return DailySnapshot(
      date: map['date'] as String,
      strengthScore: (map['strengthScore'] as num).toDouble(),
      knowledgeScore: (map['knowledgeScore'] as num).toDouble(),
      virtueScore: (map['virtueScore'] as num).toDouble(),
      socialScore: (map['socialScore'] as num).toDouble(),
      skillScore: (map['skillScore'] as num).toDouble(),
      spiritScore: (map['spiritScore'] as num).toDouble(),
      totalScore: (map['totalScore'] as num).toDouble(),
      changeValue: (map['changeValue'] as num?)?.toDouble(),
      changePercentage: (map['changePercentage'] as num?)?.toDouble(),
    );
  }
}