import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../constants/app_constants.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;
  static const int _currentVersion = 2; // Incremented version

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pondai_housing.db');
    
    developer.log('Initializing database at: $path', name: 'LOCAL_DB');
    
    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating database schema version $version', name: 'LOCAL_DB');
    
    // Landlords table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableLandlords} (
        local_id  TEXT PRIMARY KEY,
        server_id INTEGER,
        full_name TEXT NOT NULL,
        phone     TEXT NOT NULL,
        email     TEXT NOT NULL,
        address   TEXT,
        is_synced INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Houses table
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
        is_synced   INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Students table
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
        is_synced   INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Assignments table
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
        is_synced     INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Payments table
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
        is_synced      INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // Sync Queue table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncQueue} (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        entity     TEXT NOT NULL,
        action     TEXT NOT NULL,
        local_id   TEXT NOT NULL,
        server_id  INTEGER,
        payload    TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status     TEXT DEFAULT 'pending'
      )
    ''');

    // Create indexes for better query performance
    await _createIndexes(db);
    
    developer.log('Database schema created successfully', name: 'LOCAL_DB');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from $oldVersion to $newVersion', name: 'LOCAL_DB');
    
    if (oldVersion < 2) {
      // Add missing columns for version 2
      final tables = [
        AppConstants.tableLandlords,
        AppConstants.tableHouses,
        AppConstants.tableStudents,
        AppConstants.tableAssignments,
      ];
      
      for (final table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN created_at TEXT');
          await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        } catch (e) {
          developer.log('Error upgrading table $table: $e', name: 'LOCAL_DB', error: e);
        }
      }
      
      // Add status column to sync queue
      try {
        await db.execute('ALTER TABLE ${AppConstants.tableSyncQueue} ADD COLUMN status TEXT DEFAULT "pending"');
      } catch (e) {
        developer.log('Error upgrading sync queue: $e', name: 'LOCAL_DB', error: e);
      }
      
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Indexes for common queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_houses_synced ON ${AppConstants.tableHouses}(is_synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_houses_landlord ON ${AppConstants.tableHouses}(landlord_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_synced ON ${AppConstants.tableStudents}(is_synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_name ON ${AppConstants.tableStudents}(full_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_active ON ${AppConstants.tableAssignments}(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_house ON ${AppConstants.tableAssignments}(house_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_date ON ${AppConstants.tablePayments}(payment_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_month ON ${AppConstants.tablePayments}(month_paid_for)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON ${AppConstants.tableSyncQueue}(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON ${AppConstants.tableSyncQueue}(created_at)');
    
    developer.log('Database indexes created', name: 'LOCAL_DB');
  }

  // ── Generic helpers ──────────────────────────────────

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final d = await db;
      return await d.query(table);
    } catch (e) {
      developer.log('Error getting all from $table: $e', name: 'LOCAL_DB', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    required String column,
    required dynamic value,
  }) async {
    try {
      final d = await db;
      return await d.query(
        table,
        where: '$column = ?',
        whereArgs: [value],
      );
    } catch (e) {
      developer.log('Error querying $table: $e', name: 'LOCAL_DB', error: e);
      return [];
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final d = await db;
      // Add timestamps if they don't exist
      if (!data.containsKey('created_at')) {
        data['created_at'] = DateTime.now().toIso8601String();
      }
      if (!data.containsKey('updated_at') && 
          (table != AppConstants.tablePayments && table != AppConstants.tableSyncQueue)) {
        data['updated_at'] = DateTime.now().toIso8601String();
      }
      
      return await d.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      developer.log('Error inserting into $table: $e', name: 'LOCAL_DB', error: e);
      return -1;
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, String localId) async {
    try {
      final d = await db;
      // Update timestamp
      if (table != AppConstants.tablePayments && table != AppConstants.tableSyncQueue) {
        data['updated_at'] = DateTime.now().toIso8601String();
      }
      
      return await d.update(
        table,
        data,
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      developer.log('Error updating $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<int> updateWhere(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final d = await db;
      if (table != AppConstants.tablePayments && table != AppConstants.tableSyncQueue) {
        data['updated_at'] = DateTime.now().toIso8601String();
      }
      
      return await d.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      developer.log('Error updating $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<int> delete(String table, String localId) async {
    try {
      final d = await db;
      return await d.delete(table, where: 'local_id = ?', whereArgs: [localId]);
    } catch (e) {
      developer.log('Error deleting from $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<int> deleteByServerId(String table, int serverId) async {
    try {
      final d = await db;
      return await d.delete(table, where: 'server_id = ?', whereArgs: [serverId]);
    } catch (e) {
      developer.log('Error deleting by server_id from $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<int> deleteWhere(String table, String where, List<dynamic> whereArgs) async {
    try {
      final d = await db;
      return await d.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      developer.log('Error deleting from $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<void> clearAndInsertAll(String table, List<Map<String, dynamic>> rows) async {
    final d = await db;
    final batch = d.batch();
    batch.delete(table);
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    developer.log('Cleared and inserted ${rows.length} rows into $table', name: 'LOCAL_DB');
  }

  Future<void> batchInsert(String table, List<Map<String, dynamic>> rows) async {
    final d = await db;
    final batch = d.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    developer.log('Batch inserted ${rows.length} rows into $table', name: 'LOCAL_DB');
  }

  // ── Sync Queue ───────────────────────────────────────

  Future<void> addToSyncQueue({
    required String entity,
    required String action,
    required String localId,
    int? serverId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final d = await db;
      await d.insert(AppConstants.tableSyncQueue, {
        'entity': entity,
        'action': action,
        'local_id': localId,
        'server_id': serverId,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      developer.log('Added to sync queue: $entity - $action', name: 'LOCAL_DB');
    } catch (e) {
      developer.log('Error adding to sync queue: $e', name: 'LOCAL_DB', error: e);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 100}) async {
    try {
      final d = await db;
      return await d.query(
        AppConstants.tableSyncQueue,
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
        limit: limit,
      );
    } catch (e) {
      developer.log('Error getting pending sync items: $e', name: 'LOCAL_DB', error: e);
      return [];
    }
  }

  Future<void> removeSyncItem(int id) async {
    try {
      final d = await db;
      await d.delete(AppConstants.tableSyncQueue, where: 'id = ?', whereArgs: [id]);
      developer.log('Removed sync item $id', name: 'LOCAL_DB');
    } catch (e) {
      developer.log('Error removing sync item: $e', name: 'LOCAL_DB', error: e);
    }
  }

  Future<void> updateSyncItemStatus(int id, String status) async {
    try {
      final d = await db;
      await d.update(
        AppConstants.tableSyncQueue,
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating sync item status: $e', name: 'LOCAL_DB', error: e);
    }
  }

  Future<void> clearSyncQueue() async {
    try {
      final d = await db;
      await d.delete(AppConstants.tableSyncQueue);
      developer.log('Cleared sync queue', name: 'LOCAL_DB');
    } catch (e) {
      developer.log('Error clearing sync queue: $e', name: 'LOCAL_DB', error: e);
    }
  }

  Future<int> getPendingSyncCount() async {
    try {
      final d = await db;
      final result = await d.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableSyncQueue} WHERE status = ?',
        ['pending'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting pending sync count: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

// Add these to your LocalDb class if needed

// For counting records
Future<int> getCount(String table) async {
  final d = await db;
  final result = await d.rawQuery('SELECT COUNT(*) as count FROM $table');
  return Sqflite.firstIntValue(result) ?? 0;
}

// For checking if record exists
Future<bool> exists(String table, String localId) async {
  final d = await db;
  final result = await d.query(
    table,
    where: 'local_id = ?',
    whereArgs: [localId],
    limit: 1,
  );
  return result.isNotEmpty;
}

// For database maintenance
Future<void> vacuum() async {
  final d = await db;
  await d.rawQuery('VACUUM');
  developer.log('Database vacuumed', name: 'LOCAL_DB');
}
  // ── Utility Methods ──────────────────────────────────

  Future<Map<String, dynamic>?> getByLocalId(String table, String localId) async {
    try {
      final d = await db;
      final result = await d.query(
        table,
        where: 'local_id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      developer.log('Error getting by local_id from $table: $e', name: 'LOCAL_DB', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getByServerId(String table, int serverId) async {
    try {
      final d = await db;
      final result = await d.query(
        table,
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      developer.log('Error getting by server_id from $table: $e', name: 'LOCAL_DB', error: e);
      return null;
    }
  }

  Future<int> getUnsyncedCount(String table) async {
    try {
      final d = await db;
      final result = await d.rawQuery(
        'SELECT COUNT(*) as count FROM $table WHERE is_synced = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting unsynced count from $table: $e', name: 'LOCAL_DB', error: e);
      return 0;
    }
  }

  Future<void> markAsSynced(String table, String localId) async {
    await update(table, {'is_synced': 1}, localId);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      developer.log('Database closed', name: 'LOCAL_DB');
    }
  }
}