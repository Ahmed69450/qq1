import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/user_fact.dart';
import 'app_database.dart';

class UserFactsDao {
  final Database _db;

  UserFactsDao(this._db);

  Future<void> insertOrUpdateFact(UserFact fact) async {
    await _db.insert(
      AppDatabase.tableUserFacts,
      fact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserFact>> getFactsForKeywords(List<String> keywords) async {
    if (keywords.isEmpty) return [];
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    for (final kw in keywords) {
      whereClauses.add('category LIKE ? OR fact_key LIKE ? OR fact_value LIKE ?');
      final arg = '%$kw%';
      whereArgs.addAll([arg, arg, arg]);
    }

    final maps = await _db.query(
      AppDatabase.tableUserFacts,
      where: whereClauses.join(' OR '),
      whereArgs: whereArgs,
      limit: 5,
    );

    return maps.map((m) => UserFact.fromMap(m)).toList();
  }
}
