import 'package:sqflite/sqflite.dart';

import '../models/daily_snapshot.dart';
import '../models/dashboard_data.dart';
import '../models/primary_attribute.dart';
import '../models/score_record.dart';
import '../models/secondary_attribute.dart';
import '../utils/formatters.dart';
import 'database_service.dart';

class AppRepository {
  AppRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<Database> get _db async => _databaseService.database;

  Future<int> createSecondaryAttribute({
    required PrimaryAttributeType primaryType,
    required String name,
    String? description,
  }) async {
    final db = await _db;
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();

    if (trimmedName.isEmpty) {
      throw Exception('二级属性名称不能为空');
    }

    final duplicated = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'primaryType = ? AND name = ?',
      whereArgs: [primaryType.key, trimmedName],
      limit: 1,
    );

    if (duplicated.isNotEmpty) {
      throw Exception('同一一级属性下已存在同名二级属性');
    }

    final now = DateTime.now().toIso8601String();

    return db.insert(
      DatabaseService.tableSecondaryAttributes,
      {
        'primaryType': primaryType.key,
        'name': trimmedName,
        'description': (trimmedDescription?.isEmpty ?? true)
            ? null
            : trimmedDescription,
        'isArchived': 0,
        'createdAt': now,
        'updatedAt': now,
      },
    );
  }

  Future<void> updateSecondaryAttribute({
    required int id,
    required PrimaryAttributeType primaryType,
    required String name,
    String? description,
  }) async {
    final db = await _db;
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();

    if (trimmedName.isEmpty) {
      throw Exception('二级属性名称不能为空');
    }

    final duplicated = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'primaryType = ? AND name = ? AND id != ?',
      whereArgs: [primaryType.key, trimmedName, id],
      limit: 1,
    );

    if (duplicated.isNotEmpty) {
      throw Exception('同一一级属性下已存在同名二级属性');
    }

    await db.update(
      DatabaseService.tableSecondaryAttributes,
      {
        'name': trimmedName,
        'description': (trimmedDescription?.isEmpty ?? true)
            ? null
            : trimmedDescription,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archiveSecondaryAttribute(int id) async {
    final db = await _db;
    await db.update(
      DatabaseService.tableSecondaryAttributes,
      {
        'isArchived': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreSecondaryAttribute(int id) async {
    final db = await _db;

    final item = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (item.isEmpty) {
      throw Exception('未找到要恢复的二级属性');
    }

    final row = item.first;
    final primaryType = row['primaryType'] as String;
    final name = row['name'] as String;

    final duplicated = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'primaryType = ? AND name = ? AND id != ?',
      whereArgs: [primaryType, name, id],
      limit: 1,
    );

    if (duplicated.isNotEmpty) {
      throw Exception('恢复失败：当前已有同名二级属性');
    }

    await db.update(
      DatabaseService.tableSecondaryAttributes,
      {
        'isArchived': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SecondaryAttribute>> getSecondaryAttributesByPrimary(
    PrimaryAttributeType primaryType, {
    bool includeArchived = false,
  }) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: includeArchived ? 'primaryType = ?' : 'primaryType = ? AND isArchived = 0',
      whereArgs: [primaryType.key],
      orderBy: 'createdAt DESC',
    );

    return rows.map(SecondaryAttribute.fromMap).toList();
  }

  Future<List<SecondaryAttribute>> getArchivedSecondaryAttributesByPrimary(
    PrimaryAttributeType primaryType,
  ) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'primaryType = ? AND isArchived = 1',
      whereArgs: [primaryType.key],
      orderBy: 'updatedAt DESC',
    );

    return rows.map(SecondaryAttribute.fromMap).toList();
  }

  Future<SecondaryAttribute?> getSecondaryAttributeById(int id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableSecondaryAttributes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return SecondaryAttribute.fromMap(rows.first);
  }

  Future<int> addScoreRecord({
    required int secondaryAttributeId,
    required double delta,
    String? note,
  }) async {
    final db = await _db;

    final secondary = await getSecondaryAttributeById(secondaryAttributeId);
    if (secondary == null) {
      throw Exception('未找到对应的二级属性');
    }

    final trimmedNote = note?.trim();
    final id = await db.insert(
      DatabaseService.tableScoreRecords,
      {
        'secondaryAttributeId': secondaryAttributeId,
        'primaryType': secondary.primaryType.key,
        'secondaryNameSnapshot': secondary.name,
        'delta': delta,
        'note': (trimmedNote?.isEmpty ?? true) ? null : trimmedNote,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    await upsertTodaySnapshot();
    return id;
  }

  Future<List<ScoreRecord>> getRecordsBySecondaryAttribute(
    int secondaryAttributeId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableScoreRecords,
      where: 'secondaryAttributeId = ?',
      whereArgs: [secondaryAttributeId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(ScoreRecord.fromMap).toList();
  }

  Future<List<ScoreRecord>> getRecentRecords({int limit = 20}) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableScoreRecords,
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return rows.map(ScoreRecord.fromMap).toList();
  }

  Future<double> getSecondaryCurrentScore(int secondaryAttributeId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(delta), 0) AS total
      FROM ${DatabaseService.tableScoreRecords}
      WHERE secondaryAttributeId = ?
      ''',
      [secondaryAttributeId],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getPrimaryContribution(PrimaryAttributeType primaryType) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(r.delta), 0) AS total
      FROM ${DatabaseService.tableScoreRecords} r
      INNER JOIN ${DatabaseService.tableSecondaryAttributes} s
      ON r.secondaryAttributeId = s.id
      WHERE s.primaryType = ?
      ''',
      [primaryType.key],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<PrimaryAttribute>> getAllPrimaryAttributes() async {
    final list = <PrimaryAttribute>[];

    for (final type in PrimaryAttributeType.values) {
      final contribution = await getPrimaryContribution(type);
      list.add(
        PrimaryAttribute(
          type: type,
          secondaryContribution: contribution,
        ),
      );
    }

    return list;
  }

  Future<double> getTotalScore() async {
    final primaryAttributes = await getAllPrimaryAttributes();
    return primaryAttributes.fold<double>(
      0.0,
      (sum, item) => sum + item.currentScore,
    );
  }

  Future<DashboardData> getDashboardData() async {
    await upsertTodaySnapshot();

    final primaryAttributes = await getAllPrimaryAttributes();
    final totalScore = primaryAttributes.fold<double>(
      0.0,
      (sum, item) => sum + item.currentScore,
    );

    final today = await getSnapshotByDate(DateTime.now());
    final yesterday = await getSnapshotByDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final recentRecords = await getRecentRecords(limit: 10);

    return DashboardData(
      primaryAttributes: primaryAttributes,
      totalScore: totalScore,
      yesterdayChangeValue: today?.changeValue,
      yesterdayChangePercentage: today?.changePercentage,
      recentRecords: recentRecords,
      todaySnapshot: today,
      yesterdaySnapshot: yesterday,
    );
  }

  Future<void> upsertTodaySnapshot() async {
    final db = await _db;
    final now = DateTime.now();
    final todayKey = AppFormatters.day(now);

    final scores = <PrimaryAttributeType, double>{};
    for (final type in PrimaryAttributeType.values) {
      final contribution = await getPrimaryContribution(type);
      scores[type] = PrimaryAttribute.baseScore + contribution;
    }

    final totalScore = scores.values.fold<double>(0.0, (a, b) => a + b);

    final yesterdayKey = AppFormatters.day(
      now.subtract(const Duration(days: 1)),
    );

    final yesterdayRows = await db.query(
      DatabaseService.tableDailySnapshots,
      where: 'date = ?',
      whereArgs: [yesterdayKey],
      limit: 1,
    );

    double? changeValue;
    double? changePercentage;

    if (yesterdayRows.isNotEmpty) {
      final yesterday = DailySnapshot.fromMap(yesterdayRows.first);
      changeValue = totalScore - yesterday.totalScore;

      if (yesterday.totalScore != 0) {
        changePercentage = (changeValue / yesterday.totalScore) * 100;
      }
    }

    await db.insert(
      DatabaseService.tableDailySnapshots,
      {
        'date': todayKey,
        'strengthScore': scores[PrimaryAttributeType.strength]!,
        'knowledgeScore': scores[PrimaryAttributeType.knowledge]!,
        'virtueScore': scores[PrimaryAttributeType.virtue]!,
        'socialScore': scores[PrimaryAttributeType.social]!,
        'skillScore': scores[PrimaryAttributeType.skill]!,
        'spiritScore': scores[PrimaryAttributeType.spirit]!,
        'totalScore': totalScore,
        'changeValue': changeValue,
        'changePercentage': changePercentage,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailySnapshot?> getSnapshotByDate(DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableDailySnapshots,
      where: 'date = ?',
      whereArgs: [AppFormatters.day(date)],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return DailySnapshot.fromMap(rows.first);
  }

  Future<List<DailySnapshot>> getRecentSnapshots({int days = 30}) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseService.tableDailySnapshots,
      orderBy: 'date DESC',
      limit: days,
    );

    return rows.map(DailySnapshot.fromMap).toList().reversed.toList();
  }

  Future<String> exportAllToJsonString() async {
    final db = await _db;
    final data = await _databaseService.exportAll(db);
    return _databaseService.encodeExportJson(data);
  }

  Future<void> importAllFromJsonString(String jsonString) async {
    final db = await _db;
    final jsonMap = _databaseService.decodeImportJson(jsonString);

    await db.transaction((txn) async {
      await _databaseService.importAllReplace(txn, jsonMap);
    });
  }
    Future<void> archiveSecondaryAttributeAndRefresh(int id) async {
    await archiveSecondaryAttribute(id);
    await upsertTodaySnapshot();
  }

  Future<void> restoreSecondaryAttributeAndRefresh(int id) async {
    await restoreSecondaryAttribute(id);
    await upsertTodaySnapshot();
  }
    Future<List<DailySnapshot>> getTrendSnapshots({int days = 7}) async {
    await upsertTodaySnapshot();
    return getRecentSnapshots(days: days);
  }

  Future<Map<PrimaryAttributeType, double>> getPrimaryScoreMapOfSnapshot(
    DailySnapshot snapshot,
  ) async {
    return {
      PrimaryAttributeType.strength: snapshot.strengthScore,
      PrimaryAttributeType.knowledge: snapshot.knowledgeScore,
      PrimaryAttributeType.virtue: snapshot.virtueScore,
      PrimaryAttributeType.social: snapshot.socialScore,
      PrimaryAttributeType.skill: snapshot.skillScore,
      PrimaryAttributeType.spirit: snapshot.spiritScore,
    };
  }

    Future<void> clearAllData() async {
    final db = await _db;
    await db.transaction((txn) async {
      await _databaseService.clearAllTables(txn);
    });
  }

  Future<void> replaceAllDataFromJsonString(String jsonString) async {
    await importAllFromJsonString(jsonString);
    await upsertTodaySnapshot();
  }

  Future<String> buildExportFileName() async {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return 'growth_system_backup_${yyyy}${mm}${dd}_${hh}${mi}${ss}.json';
  }
}