import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _dbName = 'growth_system.db';
  static const _dbVersion = 1;

  static const tableSecondaryAttributes = 'secondary_attributes';
  static const tableScoreRecords = 'score_records';
  static const tableDailySnapshots = 'daily_snapshots';

  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSecondaryAttributes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        primaryType TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_secondary_unique_active_name
      ON $tableSecondaryAttributes (primaryType, name);
    ''');

    await db.execute('''
      CREATE TABLE $tableScoreRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secondaryAttributeId INTEGER NOT NULL,
        primaryType TEXT NOT NULL,
        secondaryNameSnapshot TEXT NOT NULL,
        delta REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (secondaryAttributeId)
          REFERENCES $tableSecondaryAttributes(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_score_records_secondary_id
      ON $tableScoreRecords (secondaryAttributeId);
    ''');

    await db.execute('''
      CREATE INDEX idx_score_records_created_at
      ON $tableScoreRecords (createdAt DESC);
    ''');

    await db.execute('''
      CREATE TABLE $tableDailySnapshots (
        date TEXT PRIMARY KEY,
        strengthScore REAL NOT NULL,
        knowledgeScore REAL NOT NULL,
        virtueScore REAL NOT NULL,
        socialScore REAL NOT NULL,
        skillScore REAL NOT NULL,
        spiritScore REAL NOT NULL,
        totalScore REAL NOT NULL,
        changeValue REAL,
        changePercentage REAL
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 以后版本升级时在这里补迁移逻辑
  }

  Future<void> clearAllTables(DatabaseExecutor db) async {
    await db.delete(tableScoreRecords);
    await db.delete(tableSecondaryAttributes);
    await db.delete(tableDailySnapshots);
  }

  Future<Map<String, dynamic>> exportAll(DatabaseExecutor db) async {
    final secondaryAttributes =
        await db.query(tableSecondaryAttributes, orderBy: 'id ASC');
    final scoreRecords = await db.query(tableScoreRecords, orderBy: 'id ASC');
    final dailySnapshots =
        await db.query(tableDailySnapshots, orderBy: 'date ASC');

    return {
      'version': _dbVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'secondaryAttributes': secondaryAttributes,
      'scoreRecords': scoreRecords,
      'dailySnapshots': dailySnapshots,
    };
  }

  Future<void> importAllReplace(
    DatabaseExecutor db,
    Map<String, dynamic> jsonMap,
  ) async {
    final secondaryAttributes =
        (jsonMap['secondaryAttributes'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final scoreRecords =
        (jsonMap['scoreRecords'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final dailySnapshots =
        (jsonMap['dailySnapshots'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

    await clearAllTables(db);

    for (final item in secondaryAttributes) {
      await db.insert(tableSecondaryAttributes, item);
    }

    for (final item in scoreRecords) {
      await db.insert(tableScoreRecords, item);
    }

    for (final item in dailySnapshots) {
      await db.insert(tableDailySnapshots, item);
    }
  }

  String encodeExportJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Map<String, dynamic> decodeImportJson(String source) {
    return jsonDecode(source) as Map<String, dynamic>;
  }
}