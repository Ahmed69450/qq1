# Offline Hybrid Voice Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 100% offline Arabic Voice Assistant for BYD DiLink head units (Android 10+) using Flutter, Clean Architecture, Dart FFI for local AI inference, and native Android foreground and overlay services.

**Architecture:** A decoupled hybrid architecture where Android native Kotlin services handle low-overhead background audio capture (Vosk KWS), overlay management, and BYD vendor intents. Flutter with Dart FFI powers the dual AI engine (Engine A: fast semantic router, Engine B: dynamic llama.cpp LLM fallback), Piper TTS synthesis, and the bottom capsule HUD overlay.

**Tech Stack:** Flutter 3.x / Dart 3.x, Kotlin (Android 10+), Dart FFI, sqflite, Vosk C-API, ONNX Runtime C-API, llama.cpp, Piper C++ TTS.

**Spec:** `docs/superpowers/specs/2026-10-08-offline-car-assistant-design.md`

## Global Constraints

- **Platform Target:** Android 10+ (API Level 29+), arm64-v8a / armeabi-v7a.
- **Offline Guarantee:** Zero network calls or external cloud dependencies for core assistant functionality.
- **Language Scope:** Strict Arabic processing (Regex `\u0600-\u06FF`, Iraqi/Arabic stopwords, phonetic number/symbol expansion for TTS).
- **Thermal & Compute Bound:** Engine B LLM strictly limited to 2-3 CPU threads and CPU-only execution (`n_gpu_layers = 0`).
- **Response Latency:** Engine A semantic matches must execute within <= 150ms.
- **Package Identifiers:** Android package `com.byd.assistant`.

## Review Focus

1. **Arabic diacritics and character variants:** Input containing mixed Tashkeel (`َ`, `ِ`, `ُ`, `ّ`) or various Alef forms (`أ`, `إ`, `آ`) must normalize to bare letters without throwing parse exceptions or degrading semantic matching.
2. **TTS symbol crash/misreading:** Symbols like `%`, `°C`, English numerals `1-9`, or Markdown formatting (`**`, `##`) emitted by LLM fallback must be converted to spoken Arabic or stripped before reaching Piper TTS.
3. **Missing BYD vendor hardware on non-BYD hosts:** Running on standard Android tablets or emulators must gracefully trigger the simulated fallback without crashing or throwing unhandled `ActivityNotFoundException`.
4. **Out of memory during model loading:** Attempting to load an invalid or corrupt `.gguf` / `.onnx` file must be caught gracefully and return a structured error rather than crashing the Flutter VM.
5. **Simultaneous speech while TTS is playing:** Vosk recognizer must temporarily mute or ignore microphone buffers during TTS playback to avoid acoustic feedback loops (echo self-triggering).

---

### Task 1: Project Scaffolding & Dependencies Configuration

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `test/smoke_test.dart`

**Interfaces:**
- Consumes: None (Root setup)
- Produces: Base Flutter project configuration with `sqflite`, `path_provider`, `flutter_test`.

- [ ] **Step 1: Write the failing smoke test**

```dart
// test/smoke_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verify test harness is operational', () {
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails (missing Flutter setup)**

Run: `flutter test test/smoke_test.dart`
Expected: FAIL (missing `pubspec.yaml` or project metadata)

- [ ] **Step 3: Write minimal implementation**

```yaml
# pubspec.yaml
name: offline_car_assistant
description: Offline Hybrid Voice Assistant for BYD DiLink Head Unit.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/grammar/
```

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/smoke_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml analysis_options.yaml test/smoke_test.dart
git commit -m "chore: scaffold Flutter project configuration and test harness"
```

---

### Task 2: Core Domain Entities & Models

**Files:**
- Create: `lib/domain/entities/car_command.dart`
- Create: `lib/domain/entities/intent_match.dart`
- Create: `lib/domain/entities/user_fact.dart`
- Create: `lib/domain/entities/voice_state.dart`
- Test: `test/domain/entities_test.dart`

**Interfaces:**
- Consumes: Dart core primitives
- Produces: `CarCommand`, `CarActionType`, `IntentMatch`, `UserFact`, `VoiceState`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';
import 'package:offline_car_assistant/domain/entities/intent_match.dart';
import 'package:offline_car_assistant/domain/entities/user_fact.dart';

void main() {
  test('CarCommand should instantiate correctly with parameters', () {
    final cmd = CarCommand(
      action: CarActionType.airConditioner,
      zone: 'driver',
      value: 22,
      rawIntent: 'com.byd.intent.action.AC_CONTROL',
    );
    expect(cmd.action, equals(CarActionType.airConditioner));
    expect(cmd.value, equals(22));
    expect(cmd.toMap()['action'], equals('airConditioner'));
  });

  test('IntentMatch should properly calculate isConfident', () {
    final match = IntentMatch(
      action: CarActionType.windows,
      confidence: 0.85,
      spokenConfirmation: 'تم فتح النوافذ',
    );
    expect(match.isConfident(0.70), isTrue);

    final lowMatch = IntentMatch(
      action: CarActionType.unknown,
      confidence: 0.45,
      spokenConfirmation: '',
    );
    expect(lowMatch.isConfident(0.70), isFalse);
  });

  test('UserFact serialization and deserialization', () {
    final fact = UserFact(
      id: 1,
      category: 'climate',
      key: 'preferred_temp',
      value: '22',
      confidence: 0.9,
    );
    final map = fact.toMap();
    final reconstructed = UserFact.fromMap(map);
    expect(reconstructed.key, equals('preferred_temp'));
    expect(reconstructed.value, equals('22'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/entities_test.dart`
Expected: FAIL (types not found)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/domain/entities/car_command.dart
enum CarActionType {
  airConditioner,
  windows,
  sunroof,
  seats,
  media,
  unknown,
}

class CarCommand {
  final CarActionType action;
  final String zone;
  final dynamic value;
  final String rawIntent;

  const CarCommand({
    required this.action,
    this.zone = 'all',
    this.value,
    required this.rawIntent,
  });

  Map<String, dynamic> toMap() => {
    'action': action.name,
    'zone': zone,
    'value': value,
    'rawIntent': rawIntent,
  };
}
```

```dart
// lib/domain/entities/intent_match.dart
import 'car_command.dart';

class IntentMatch {
  final CarActionType action;
  final double confidence;
  final String spokenConfirmation;
  final Map<String, dynamic> parameters;

  const IntentMatch({
    required this.action,
    required this.confidence,
    required this.spokenConfirmation,
    this.parameters = const {},
  });

  bool isConfident(double threshold) => confidence >= threshold;
}
```

```dart
// lib/domain/entities/user_fact.dart
class UserFact {
  final int? id;
  final String category;
  final String key;
  final String value;
  final double confidence;
  final int updatedAt;

  UserFact({
    this.id,
    required this.category,
    required this.key,
    required this.value,
    this.confidence = 1.0,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'fact_key': key,
    'fact_value': value,
    'confidence': confidence,
    'updated_at': updatedAt,
  };

  factory UserFact.fromMap(Map<String, dynamic> map) => UserFact(
    id: map['id'] as int?,
    category: map['category'] as String,
    key: map['fact_key'] as String,
    value: map['fact_value'] as String,
    confidence: (map['confidence'] as num).toDouble(),
    updatedAt: map['updated_at'] as int,
  );
}
```

```dart
// lib/domain/entities/voice_state.dart
enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/entities_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/ test/domain/entities_test.dart
git commit -m "feat: implement core domain entities and data models"
```

---

### Task 3: Arabic Text Normalizer & Dialect Stopwords

**Files:**
- Create: `lib/core/constants/arabic_stopwords.dart`
- Create: `lib/core/utils/arabic_normalizer.dart`
- Test: `test/core/arabic_normalizer_test.dart`

**Interfaces:**
- Consumes: Dart core `String`, `RegExp`
- Produces: `ArabicNormalizer.normalize(String)`, `ArabicNormalizer.tokenize(String)`, `arabicIraqiStopwords`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/arabic_normalizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/core/utils/arabic_normalizer.dart';

void main() {
  test('normalizes Alef variants to bare Alef', () {
    expect(ArabicNormalizer.normalize('أحمد إبراهيم آمنة'), equals('احمد ابراهيم امنه'));
  });

  test('normalizes Taa Marbuta to Haa', () {
    expect(ArabicNormalizer.normalize('سيارة جميلة'), equals('سياره جميله'));
  });

  test('strips Arabic diacritics (Tashkeel)', () {
    expect(ArabicNormalizer.normalize('شَغِّلْ التَّبْرِيدَ'), equals('شغل التبريد'));
  });

  test('removes non-Arabic and non-digit characters', () {
    expect(ArabicNormalizer.normalize('شغل المكيف! #100%'), equals('شغل المكيف 100'));
  });

  test('removes dialect stopwords correctly', () {
    final tokens = ArabicNormalizer.tokenizeWithoutStopwords('شنو شغل لي المكيف بالسيارة');
    expect(tokens, contains('شغل'));
    expect(tokens, contains('المكيف'));
    expect(tokens, isNot(contains('شنو')));
    expect(tokens, isNot(contains('لي')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/arabic_normalizer_test.dart`
Expected: FAIL (missing `ArabicNormalizer`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/constants/arabic_stopwords.dart
const Set<String> arabicIraqiStopwords = {
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'تم', 'كان',
  'شنو', 'شكو', 'شلون', 'ليش', 'وين', 'هسه', 'دا', 'راح', 'فد', 'مال',
  'لي', 'لك', 'لنا', 'يا', 'اريد', 'بدي', 'عفية', 'بلة',
};
```

```dart
// lib/core/utils/arabic_normalizer.dart
import '../constants/arabic_stopwords.dart';

class ArabicNormalizer {
  static final RegExp _tashkeel = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
  static final RegExp _alef = RegExp(r'[إأآ]');
  static final RegExp _taaMarbuta = RegExp(r'ة');
  static final RegExp _allowedChars = RegExp(r'[^\u0600-\u06FF0-9\s]');
  static final RegExp _multipleSpaces = RegExp(r'\s+');

  static String normalize(String text) {
    if (text.isEmpty) return '';
    var result = text;
    result = result.replaceAll(_tashkeel, '');
    result = result.replaceAll(_alef, 'ا');
    result = result.replaceAll(_taaMarbuta, 'ه');
    result = result.replaceAll('ى', 'ي');
    result = result.replaceAll(_allowedChars, ' ');
    result = result.replaceAll(_multipleSpaces, ' ').trim();
    return result;
  }

  static List<String> tokenize(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return [];
    return normalized.split(' ');
  }

  static List<String> tokenizeWithoutStopwords(String text) {
    final tokens = tokenize(text);
    return tokens.where((t) => !arabicIraqiStopwords.contains(t)).toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/arabic_normalizer_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/ lib/core/utils/ test/core/arabic_normalizer_test.dart
git commit -m "feat: implement Arabic normalization and dialect stopword removal"
```

---

### Task 4: TTS Sanitizer & Spoken Arabic Formatter

**Files:**
- Create: `lib/core/utils/tts_sanitizer.dart`
- Test: `test/core/tts_sanitizer_test.dart`

**Interfaces:**
- Consumes: Raw text generated from LLM or intent results
- Produces: `TtsSanitizer.sanitizeForSpeech(String)` returning clean, spoken Arabic text

- [ ] **Step 1: Write the failing test**

```dart
// test/core/tts_sanitizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/core/utils/tts_sanitizer.dart';

void main() {
  test('strips Markdown formatting elements', () {
    final raw = '**تم تفعيل** التبريد بنجاح! ## التفاصيل: - حرارة 22';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, isNot(contains('**')));
    expect(clean, isNot(contains('##')));
    expect(clean, isNot(contains('-')));
  });

  test('strips emojis', () {
    final raw = 'صباح الخير 🚗❄️ تم ضبط الجو 👍';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, equals('صباح الخير تم ضبط الجو'));
  });

  test('converts symbols into Arabic spoken words', () {
    final raw = 'نسبة الشحن 85% والحرارة 24°C والسرعة 80km/h';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, contains('بالمئة'));
    expect(clean, contains('درجة مئوية'));
    expect(clean, contains('كيلومتر بالساعة'));
  });

  test('converts basic numbers into spoken Arabic words', () {
    final raw = 'الحرارة 22';
    final clean = TtsSanitizer.sanitizeForSpeech(raw);
    expect(clean, contains('اثنين وعشرين'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/tts_sanitizer_test.dart`
Expected: FAIL (missing `TtsSanitizer`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/utils/tts_sanitizer.dart
class TtsSanitizer {
  static final RegExp _markdown = RegExp(r'[*#_~`>\[\]\(\)\-]');
  static final RegExp _emojis = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );
  static final RegExp _spaces = RegExp(r'\s+');

  static final Map<int, String> _smallNumbers = {
    0: 'صفر', 1: 'واحد', 2: 'اثنين', 3: 'ثلاثة', 4: 'أربعة',
    5: 'خمسة', 6: 'ستة', 7: 'سبعة', 8: 'ثمانية', 9: 'تسعة',
    10: 'عشرة', 11: 'أحد عشر', 12: 'اثنا عشر', 13: 'ثلاثة عشر',
    14: 'أربعة عشر', 15: 'خمسة عشر', 16: 'ستة عشر', 17: 'سبعة عشر',
    18: 'ثمانية عشر', 19: 'تسعة عشر', 20: 'عشرين', 30: 'ثلاثين',
    40: 'أربعين', 50: 'خمسين', 60: 'ستين', 70: 'سبعين',
    80: 'ثمانين', 90: 'تسعين', 100: 'مئة',
  };

  static String numberToSpokenArabic(int number) {
    if (_smallNumbers.containsKey(number)) return _smallNumbers[number]!;
    if (number > 20 && number < 100) {
      final unit = number % 10;
      final tens = (number ~/ 10) * 10;
      if (unit == 0) return _smallNumbers[tens]!;
      return '${_smallNumbers[unit]} و${_smallNumbers[tens]}';
    }
    return number.toString();
  }

  static String sanitizeForSpeech(String text) {
    if (text.isEmpty) return '';
    var result = text;
    result = result.replaceAll(_markdown, ' ');
    result = result.replaceAll(_emojis, ' ');
    result = result.replaceAll('%', ' بالمئة ');
    result = result.replaceAll('°C', ' درجة مئوية ');
    result = result.replaceAll('C°', ' درجة مئوية ');
    result = result.replaceAll('km/h', ' كيلومتر بالساعة ');
    result = result.replaceAll('+', ' زائد ');

    // Convert 1-2 digit numbers to Arabic spoken words
    result = result.replaceAllMapped(RegExp(r'\b\d{1,2}\b'), (match) {
      final val = int.tryParse(match.group(0)!);
      return val != null ? ' ${numberToSpokenArabic(val)} ' : match.group(0)!;
    });

    result = result.replaceAll(_spaces, ' ').trim();
    return result;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/tts_sanitizer_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/tts_sanitizer.dart test/core/tts_sanitizer_test.dart
git commit -m "feat: implement TTS phonetic sanitizer and symbol converter"
```

---

### Task 5: Local Database & User Facts DAO (sqflite RAG)

**Files:**
- Create: `lib/data/datasources/local_db/app_database.dart`
- Create: `lib/data/datasources/local_db/user_facts_dao.dart`
- Test: `test/data/local_db_test.dart`

**Interfaces:**
- Consumes: `sqflite_common_ffi` (for testing/runtime) and `UserFact` entity
- Produces: `AppDatabase.getDatabase()`, `UserFactsDao.insertOrUpdateFact()`, `UserFactsDao.getFactsForKeywords()`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/local_db_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/local_db_test.dart`
Expected: FAIL (missing `AppDatabase` and `UserFactsDao`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/datasources/local_db/app_database.dart
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
```

```dart
// lib/data/datasources/local_db/user_facts_dao.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/local_db_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/datasources/local_db/ test/data/local_db_test.dart
git commit -m "feat: implement sqflite database schema and UserFactsDao for RAG"
```

---

### Task 6: Engine A Semantic Router & Canonical Intent Catalog

**Files:**
- Create: `lib/engines/engine_a_semantic/intent_catalog.dart`
- Create: `lib/engines/engine_a_semantic/semantic_router.dart`
- Test: `test/engines/semantic_router_test.dart`

**Interfaces:**
- Consumes: Normalized Arabic query tokens
- Produces: `SemanticRouter.matchIntent(String query)` returning `IntentMatch?` with score >= 0.70

- [ ] **Step 1: Write the failing test**

```dart
// test/engines/semantic_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';
import 'package:offline_car_assistant/engines/engine_a_semantic/semantic_router.dart';

void main() {
  late SemanticRouter router;

  setUp(() {
    router = SemanticRouter();
  });

  test('matches AC command with high confidence', () {
    final match = router.matchIntent('شغل التبريد فدوه');
    expect(match, isNotNull);
    expect(match!.action, equals(CarActionType.airConditioner));
    expect(match.confidence, greaterThanOrEqualTo(0.70));
    expect(match.spokenConfirmation, contains('التبريد'));
  });

  test('matches Window command with high confidence', () {
    final match = router.matchIntent('افتح الجامات او الشبابيك');
    expect(match, isNotNull);
    expect(match!.action, equals(CarActionType.windows));
    expect(match.confidence, greaterThanOrEqualTo(0.70));
  });

  test('returns null or low score for open conversational queries', () {
    final match = router.matchIntent('من هو مخترع السيارة الكهربائية؟');
    expect(match, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engines/semantic_router_test.dart`
Expected: FAIL (missing `SemanticRouter`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/engines/engine_a_semantic/intent_catalog.dart
import '../../domain/entities/car_command.dart';

class CanonicalIntent {
  final CarActionType action;
  final List<String> triggerKeywords;
  final String confirmationResponse;
  final Map<String, dynamic> defaultParams;

  const CanonicalIntent({
    required this.action,
    required this.triggerKeywords,
    required this.confirmationResponse,
    this.defaultParams = const {},
  });
}

final List<CanonicalIntent> canonicalCatalog = [
  CanonicalIntent(
    action: CarActionType.airConditioner,
    triggerKeywords: ['تبريد', 'مكيف', 'حراره', 'سبلت', 'بروده', 'ايسي'],
    confirmationResponse: 'صار تدلل، شغلت التبريد',
  ),
  CanonicalIntent(
    action: CarActionType.windows,
    triggerKeywords: ['جامه', 'جامات', 'شباك', 'شبابيك', 'نافذه', 'نوافذ'],
    confirmationResponse: 'تم فتح النوافذ',
  ),
  CanonicalIntent(
    action: CarActionType.sunroof,
    triggerKeywords: ['فتحه', 'سقف', 'بانوراما'],
    confirmationResponse: 'تم تحريك فتحة السقف',
  ),
  CanonicalIntent(
    action: CarActionType.seats,
    triggerKeywords: ['كشن', 'كشنات', 'مقعد', 'مقاعد', 'تدفئه', 'مساج'],
    confirmationResponse: 'تم تشغيل تدفئة المقاعد',
  ),
];
```

```dart
// lib/engines/engine_a_semantic/semantic_router.dart
import '../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/intent_match.dart';
import 'intent_catalog.dart';

class SemanticRouter {
  final double confidenceThreshold;

  SemanticRouter({this.confidenceThreshold = 0.70});

  IntentMatch? matchIntent(String rawQuery) {
    final normalized = ArabicNormalizer.normalize(rawQuery);
    final tokens = ArabicNormalizer.tokenize(normalized);

    CanonicalIntent? bestMatch;
    double highestScore = 0.0;

    for (final intent in canonicalCatalog) {
      int matchedCount = 0;
      for (final kw in intent.triggerKeywords) {
        final normalizedKw = ArabicNormalizer.normalize(kw);
        if (tokens.any((t) => t.contains(normalizedKw) || normalizedKw.contains(t))) {
          matchedCount++;
        }
      }

      if (matchedCount > 0) {
        // Calculate semantic keyword density score
        final score = (matchedCount / intent.triggerKeywords.length).clamp(0.0, 1.0) * 0.4 + 0.6;
        if (score > highestScore) {
          highestScore = score;
          bestMatch = intent;
        }
      }
    }

    if (bestMatch != null && highestScore >= confidenceThreshold) {
      return IntentMatch(
        action: bestMatch.action,
        confidence: highestScore,
        spokenConfirmation: bestMatch.confirmationResponse,
        parameters: bestMatch.defaultParams,
      );
    }

    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engines/semantic_router_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/engines/engine_a_semantic/ test/engines/semantic_router_test.dart
git commit -m "feat: implement fast semantic router and canonical intent catalog"
```

---

### Task 7: Engine B System Prompt Builder & Context Synthesizer

**Files:**
- Create: `lib/engines/engine_b_llm/prompt_builder.dart`
- Test: `test/engines/prompt_builder_test.dart`

**Interfaces:**
- Consumes: User query, Screen context JSON, Location String, List<UserFact>
- Produces: `PromptBuilder.buildLlmPrompt(...)` returning formatted LLM prompt string

- [ ] **Step 1: Write the failing test**

```dart
// test/engines/prompt_builder_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/user_fact.dart';
import 'package:offline_car_assistant/engines/engine_b_llm/prompt_builder.dart';

void main() {
  test('constructs system prompt with Arabic dialect rules and context', () {
    final prompt = PromptBuilder.buildLlmPrompt(
      userQuery: 'وين أقرب محطة؟',
      foregroundApp: 'com.google.android.apps.maps',
      screenText: 'شارع فلسطين - بغداد',
      location: 'بغداد، العراق',
      facts: [
        UserFact(category: 'preference', key: 'fuel_type', value: 'بنزين محسن'),
      ],
    );

    expect(prompt, contains('أنت مساعد ذكي مدمج داخل شاشة سيارة BYD'));
    expect(prompt, contains('com.google.android.apps.maps'));
    expect(prompt, contains('شارع فلسطين - بغداد'));
    expect(prompt, contains('بنزين محسن'));
    expect(prompt, contains('وين أقرب محطة؟'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engines/prompt_builder_test.dart`
Expected: FAIL (missing `PromptBuilder`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/engines/engine_b_llm/prompt_builder.dart
import '../../domain/entities/user_fact.dart';

class PromptBuilder {
  static String buildLlmPrompt({
    required String userQuery,
    String? foregroundApp,
    String? screenText,
    String? location,
    List<UserFact> facts = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>system');
    buffer.writeln('أنت مساعد ذكي مدمج داخل شاشة سيارة BYD.');
    buffer.writeln('القواعد:');
    buffer.writeln('1. أجب باختصار شديد (جملة أو جملتان) وباللهجة العراقية/العربية البسيطة.');
    buffer.writeln('2. تجنب علامات الماركداون والرموز التعبيرية كلياً لأن الرد سيتم نطقه صوتياً.');

    if (foregroundApp != null && foregroundApp.isNotEmpty) {
      buffer.writeln('التطبيق النشط حالياً: $foregroundApp');
    }
    if (screenText != null && screenText.isNotEmpty) {
      buffer.writeln('محتوى الشاشة: $screenText');
    }
    if (location != null && location.isNotEmpty) {
      buffer.writeln('الموقع الحالي: $location');
    }
    if (facts.isNotEmpty) {
      buffer.writeln('معلومات السائق المحفوظة:');
      for (final f in facts) {
        buffer.writeln('- ${f.key}: ${f.value}');
      }
    }
    buffer.writeln('<|im_end|>');
    buffer.writeln('<|im_start|>user');
    buffer.writeln(userQuery);
    buffer.writeln('<|im_end|>');
    buffer.writeln('<|im_start|>assistant');

    return buffer.toString();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engines/prompt_builder_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/engines/engine_b_llm/prompt_builder.dart test/engines/prompt_builder_test.dart
git commit -m "feat: implement prompt builder with dynamic screen context and RAG"
```

---

### Task 8: In-Process Car MCP Tool Dispatcher

**Files:**
- Create: `lib/engines/mcp/car_mcp_client.dart`
- Test: `test/engines/car_mcp_client_test.dart`

**Interfaces:**
- Consumes: Tool call name and arguments
- Produces: `CarMcpClient.executeTool(String toolName, Map<String, dynamic> args)`

- [ ] **Step 1: Write the failing test**

```dart
// test/engines/car_mcp_client_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/engines/mcp/car_mcp_client.dart';

void main() {
  test('executes get_car_status tool correctly', () async {
    final client = CarMcpClient();
    final result = await client.executeTool('get_car_status', {});
    expect(result['status'], equals('ok'));
    expect(result['battery_level'], isNotNull);
  });

  test('returns error for unknown tool', () async {
    final client = CarMcpClient();
    final result = await client.executeTool('non_existent_tool', {});
    expect(result['status'], equals('error'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engines/car_mcp_client_test.dart`
Expected: FAIL (missing `CarMcpClient`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/engines/mcp/car_mcp_client.dart
class CarMcpClient {
  Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'get_car_status':
        return {
          'status': 'ok',
          'speed_kmh': 0,
          'battery_level': 85,
          'ac_active': true,
          'doors_locked': true,
        };
      case 'read_screen_context':
        return {
          'status': 'ok',
          'active_app': 'com.byd.assistant',
          'visible_text': 'الشاشة الرئيسية',
        };
      default:
        return {
          'status': 'error',
          'message': 'Tool $toolName not recognized',
        };
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engines/car_mcp_client_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/engines/mcp/car_mcp_client.dart test/engines/car_mcp_client_test.dart
git commit -m "feat: implement in-process Car MCP client for vehicle telemetry tools"
```

---

### Task 9: Android Native Bridging & BYD Fallback Simulator

**Files:**
- Create: `android/app/src/main/kotlin/com/byd/assistant/bridge/CarIntentDispatcher.kt`
- Create: `android/app/src/main/kotlin/com/byd/assistant/MainActivity.kt`
- Create: `android/app/src/main/AndroidManifest.xml`
- Test: `test/native_bridge/car_control_channel_test.dart`

**Interfaces:**
- Consumes: Flutter `MethodChannel("com.byd.assistant/car_control")`
- Produces: Native Android intent dispatching with fallback logging

- [ ] **Step 1: Write the failing test**

```dart
// test/native_bridge/car_control_channel_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/data/datasources/native_bridge/car_control_channel.dart';
import 'package:offline_car_assistant/domain/entities/car_command.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CarControlChannel channel;
  final List<MethodCall> log = [];

  setUp(() {
    channel = CarControlChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.byd.assistant/car_control'), (call) async {
      log.add(call);
      return {'status': 'dispatched_simulated'};
    });
  });

  tearDown(() {
    log.clear();
  });

  test('dispatches car command to platform channel', () async {
    final cmd = CarCommand(
      action: CarActionType.airConditioner,
      zone: 'driver',
      value: 20,
      rawIntent: 'com.byd.intent.action.AC_CONTROL',
    );
    final result = await channel.dispatchCommand(cmd);
    expect(result, isTrue);
    expect(log.length, equals(1));
    expect(log.first.method, equals('dispatchCarCommand'));
    expect(log.first.arguments['action'], equals('airConditioner'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/native_bridge/car_control_channel_test.dart`
Expected: FAIL (missing `CarControlChannel`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/datasources/native_bridge/car_control_channel.dart
import 'package:flutter/services.dart';
import '../../../domain/entities/car_command.dart';

class CarControlChannel {
  static const MethodChannel _channel = MethodChannel('com.byd.assistant/car_control');

  Future<bool> dispatchCommand(CarCommand command) async {
    try {
      final res = await _channel.invokeMethod<Map>('dispatchCarCommand', command.toMap());
      return res != null;
    } on PlatformException {
      return false;
    }
  }
}
```

```kotlin
// android/app/src/main/kotlin/com/byd/assistant/bridge/CarIntentDispatcher.kt
package com.byd.assistant.bridge

import android.content.Context
import android.content.Intent
import android.util.Log

class CarIntentDispatcher(private val context: Context) {
    companion object {
        private const val TAG = "BYD_SIMULATOR"
    }

    fun dispatch(action: String, extras: Map<String, Any?>): Boolean {
        return try {
            val intent = Intent("com.byd.intent.action.$action").apply {
                extras.forEach { (k, v) ->
                    when (v) {
                        is String -> putExtra(k, v)
                        is Int -> putExtra(k, v)
                        is Double -> putExtra(k, v)
                        is Boolean -> putExtra(k, v)
                    }
                }
            }
            context.sendBroadcast(intent)
            Log.i(TAG, "Dispatched broadcast for action: $action with extras: $extras")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Hardware broadcast fallback triggered: ${e.message}")
            true
        }
    }
}
```

```kotlin
// android/app/src/main/kotlin/com/byd/assistant/MainActivity.kt
package com.byd.assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.byd.assistant.bridge.CarIntentDispatcher

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.byd.assistant/car_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val dispatcher = CarIntentDispatcher(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "dispatchCarCommand") {
                val action = call.argument<String>("action") ?: "unknown"
                val map = call.arguments as? Map<String, Any?> ?: emptyMap()
                val success = dispatcher.dispatch(action, map)
                result.success(mapOf("status" to if (success) "dispatched" else "failed"))
            } else {
                result.notImplemented()
            }
        }
    }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.byd.assistant">
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>

    <application
        android:label="BYD Assistant"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@android:style/Theme.Black.NoTitleBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/native_bridge/car_control_channel_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add android/ lib/data/datasources/native_bridge/ test/native_bridge/
git commit -m "feat: implement Android native BYD intent dispatcher and fallback simulator"
```

---

### Task 10: Presentation - Bottom Capsule HUD Overlay & Visualizer

**Files:**
- Create: `lib/presentation/hud/wave_visualizer.dart`
- Create: `lib/presentation/hud/bottom_capsule_overlay.dart`
- Create: `lib/overlay_main.dart`
- Test: `test/presentation/hud_widget_test.dart`

**Interfaces:**
- Consumes: `VoiceState`, recognized text string, amplitude values
- Produces: Flutter Widget `BottomCapsuleOverlay` and entrypoint `overlayMain`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/presentation/hud_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/domain/entities/voice_state.dart';
import 'package:offline_car_assistant/presentation/hud/bottom_capsule_overlay.dart';

void main() {
  testWidgets('BottomCapsuleOverlay renders voice state and text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BottomCapsuleOverlay(
            voiceState: VoiceState.listening,
            recognizedText: 'شغل التبريد',
          ),
        ),
      ),
    );

    expect(find.text('شغل التبريد'), findsOneWidget);
    expect(find.byType(BottomCapsuleOverlay), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/hud_widget_test.dart`
Expected: FAIL (missing `BottomCapsuleOverlay`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/hud/wave_visualizer.dart
import 'package:flutter/material.dart';

class WaveVisualizer extends StatelessWidget {
  final bool isListening;

  const WaveVisualizer({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final height = isListening ? (12.0 + (index % 3) * 8.0) : 6.0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
```

```dart
// lib/presentation/hud/bottom_capsule_overlay.dart
import 'package:flutter/material.dart';
import '../../domain/entities/voice_state.dart';
import 'wave_visualizer.dart';

class BottomCapsuleOverlay extends StatelessWidget {
  final VoiceState voiceState;
  final String recognizedText;
  final VoidCallback? onDismiss;

  const BottomCapsuleOverlay({
    super.key,
    required this.voiceState,
    required this.recognizedText,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xDD181818),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaveVisualizer(isListening: voiceState == VoiceState.listening),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                recognizedText.isEmpty ? 'المساعد يستمع...' : recognizedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/overlay_main.dart
import 'package:flutter/material.dart';
import 'domain/entities/voice_state.dart';
import 'presentation/hud/bottom_capsule_overlay.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: BottomCapsuleOverlay(
          voiceState: VoiceState.listening,
          recognizedText: 'جاهز للاستماع...',
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/hud_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/hud/ lib/overlay_main.dart test/presentation/hud_widget_test.dart
git commit -m "feat: implement bottom capsule HUD overlay and wave visualizer"
```

---

### Task 11: Presentation - Settings Dashboard & Model Manager

**Files:**
- Create: `lib/presentation/settings/model_manager_screen.dart`
- Create: `lib/presentation/settings/settings_screen.dart`
- Create: `lib/main.dart`
- Test: `test/presentation/settings_screen_test.dart`

**Interfaces:**
- Consumes: Storage paths, settings state
- Produces: Fullscreen Flutter UI dashboard

- [ ] **Step 1: Write the failing widget test**

```dart
// test/presentation/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/presentation/settings/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders header and model options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('إعدادات المساعد الصوتي'), findsOneWidget);
    expect(find.text('إدارة النماذج الذكية (LLM & ONNX)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/settings_screen_test.dart`
Expected: FAIL (missing `SettingsScreen`)

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/settings/model_manager_screen.dart
import 'package:flutter/material.dart';

class ModelManagerScreen extends StatelessWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة النماذج (Model Manager)'),
        backgroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF222222),
            child: ListTile(
              leading: const Icon(Icons.sd_storage, color: Colors.cyanAccent),
              title: const Text('نموذج LLM (.gguf)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('افتراضي: Qwen2.5-0.5B-Instruct-Q4_K_M.gguf', style: TextStyle(color: Colors.white70)),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('استيراد من USB'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF222222),
            child: ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.cyanAccent),
              title: const Text('نموذج الصوت Piper (.onnx)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('افتراضي: ar_JO-kareem-low.onnx', style: TextStyle(color: Colors.white70)),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('تغيير الصوت'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'model_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('إعدادات المساعد الصوتي'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.cyanAccent),
            title: const Text('إدارة النماذج الذكية (LLM & ONNX)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('تحديد نماذج GGUF وPiper من الفلاشة أو الذاكرة', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelManagerScreen()),
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.mic, color: Colors.cyanAccent),
            title: const Text('كلمة التنبيه (Wake Word)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('الافتراضي: "يا سيارة" (تعديل القواعد الصوتية)', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.cyanAccent),
            title: const Text('مختبر أوامر BYD (Sandbox)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('اختبار إرسال أوامر التكييف والنوافذ والمحاكي', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'presentation/settings/settings_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'BYD Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SettingsScreen(),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/settings_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/settings/ lib/main.dart test/presentation/settings_screen_test.dart
git commit -m "feat: implement settings dashboard and model manager screen"
```
