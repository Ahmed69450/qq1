import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offline_car_assistant/data/datasources/local_db/app_database.dart';
import 'package:offline_car_assistant/data/datasources/local_db/user_facts_dao.dart';
import 'package:offline_car_assistant/domain/entities/user_fact.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database inserts and queries relevant user facts', () async {
    final db = await AppDatabase.createInMemory();
    final dao = UserFactsDao(db);

    await dao.insertOrUpdateFact(UserFact(
      category: 'climate',
      key: 'preferred_temp',
      value: '22',
    ));
    await dao.insertOrUpdateFact(UserFact(
      category: 'navigation',
      key: 'home_location',
      value: 'المنصور',
    ));

    final climateFacts = await dao.getFactsForKeywords(['حرارة', 'تبريد', 'climate']);
    expect(climateFacts.length, equals(1));
    expect(climateFacts.first.value, equals('22'));

    final navFacts = await dao.getFactsForKeywords(['البيت', 'navigation']);
    expect(navFacts.length, equals(1));
    expect(navFacts.first.value, equals('المنصور'));
  });
}
