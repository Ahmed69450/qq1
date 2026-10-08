import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String tableUserFacts = 'user_facts';
  static const String tableSettings = 'assistant_settings';

  static Future<Database> createInMemory() async {
    return await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: _createDb,
    );
  }

  static Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUserFacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        fact_key TEXT NOT NULL UNIQUE,
        fact_value TEXT NOT NULL,
        confidence REAL NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
