import 'dart:convert'; // Moved from inside the method to the top
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'pondai_housing.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableLandlords} (
        local_id  TEXT PRIMARY KEY,
        server_id INTEGER,
        full_name TEXT NOT NULL,
        phone     TEXT NOT NULL,
        email     TEXT NOT NULL,
        address   TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableHouses} (
        local_id    TEXT PRIMARY KEY,
        server_id   INTEGER,
        landlord_id INTEGER,
        landlord    TEXT,
        address     TEXT NOT NULL,
        total_rooms INTEGER DEFAULT 1,
        rent_per_room REAL DEFAULT 0,
        status      TEXT DEFAULT 'available',
        latitude    REAL,
        longitude   REAL,
        is_synced   INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudents} (
        local_id    TEXT PRIMARY KEY,
        server_id   INTEGER,
        full_name   TEXT NOT NULL,
        phone       TEXT NOT NULL,
        email       TEXT NOT NULL,
        university  TEXT,
        course      TEXT,
        national_id TEXT,
        is_synced   INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAssignments} (
        local_id      TEXT PRIMARY KEY,
        server_id     INTEGER,
        student_id    INTEGER,
        house_id      INTEGER,
        student_name  TEXT,
        house_address TEXT,
        room_number   TEXT,
        start_date    TEXT NOT NULL,
        end_date      TEXT,
        status        TEXT DEFAULT 'active',
        is_synced     INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tablePayments} (
        local_id       TEXT PRIMARY KEY,
        server_id      INTEGER,
        assignment_id  INTEGER,
        student_name   TEXT,
        amount         REAL NOT NULL,
        payment_date   TEXT NOT NULL,
        month_paid_for TEXT NOT NULL,
        method         TEXT DEFAULT 'cash',
        notes          TEXT,
        is_synced      INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncQueue} (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        entity     TEXT NOT NULL,
        action     TEXT NOT NULL,
        local_id   TEXT NOT NULL,
        server_id  INTEGER,
        payload    TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── Generic helpers ──────────────────────────────────

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final d = await db;
    return d.query(table);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final d = await db;
    return d.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, String localId) async {
    final d = await db;
    return d.update(table, data, where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<int> delete(String table, String localId) async {
    final d = await db;
    return d.delete(table, where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<int> deleteByServerId(String table, int serverId) async {
    final d = await db;
    return d.delete(table, where: 'server_id = ?', whereArgs: [serverId]);
  }

  Future<void> clearAndInsertAll(String table, List<Map<String, dynamic>> rows) async {
    final d = await db;
    final batch = d.batch();
    batch.delete(table);
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ── Sync Queue ───────────────────────────────────────

  Future<void> addToSyncQueue({
    required String entity,
    required String action,
    required String localId,
    int? serverId,
    required Map<String, dynamic> payload,
  }) async {
    final d = await db;
    await d.insert(AppConstants.tableSyncQueue, {
      'entity':     entity,
      'action':     action,
      'local_id':   localId,
      'server_id':  serverId,
      'payload':    jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final d = await db;
    return d.query(AppConstants.tableSyncQueue, orderBy: 'created_at ASC');
  }

  Future<void> removeSyncItem(int id) async {
    final d = await db;
    await d.delete(AppConstants.tableSyncQueue, where: 'id = ?', whereArgs: [id]);
  }
}