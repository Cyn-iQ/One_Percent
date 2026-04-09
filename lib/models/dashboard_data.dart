import 'daily_snapshot.dart';
import 'primary_attribute.dart';
import 'score_record.dart';

class DashboardData {
  final List<PrimaryAttribute> primaryAttributes;
  final double totalScore;
  final double? yesterdayChangeValue;
  final double? yesterdayChangePercentage;
  final List<ScoreRecord> recentRecords;
  final DailySnapshot? todaySnapshot;
  final DailySnapshot? yesterdaySnapshot;

  const DashboardData({
    required this.primaryAttributes,
    required this.totalScore,
    required this.yesterdayChangeValue,
    required this.yesterdayChangePercentage,
    required this.recentRecords,
    this.todaySnapshot,
    this.yesterdaySnapshot,
  });

  PrimaryAttribute getByType(PrimaryAttributeType type) {
    return primaryAttributes.firstWhere((e) => e.type == type);
  }
}