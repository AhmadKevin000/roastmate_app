import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/engines/recommendation_engine.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late RecommendationEngine engine;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    for (final stmt in kCreateTableStatements) {
      await db.execute(stmt);
    }

    // Seed data dasar untuk test
    await db.insert('brew_methods', {
      'method_id': 'M001',
      'method_name': 'Pour Over (V60)',
      'method_type': 'pour_over',
      'description': 'Manual drip V60',
    });
    await db.insert('brew_methods', {
      'method_id': 'M002',
      'method_name': 'French Press',
      'method_type': 'immersion',
      'description': 'Plunger immersion',
    });

    await db.insert('brew_recipes', {
      'recipe_id': 'R001',
      'method_id': 'M001',
      'species': 'Arabica',
      'quality_profile': 'High',
      'roast_context': 'Light',
      'dose_g': 15,
      'water_volume_ml': 225,
      'grind_size': 'Medium-Fine',
      'temperature_c': 92,
      'brewing_time_s': 165,
      'source': 'SCA Standard',
      'is_default': 1,
      'steps': jsonEncode(['Step 1', 'Step 2']),
      'notes': 'Optimal aroma fruity',
    });

    engine = RecommendationEngine(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecommendationEngine Tests', () {
    test('Green bean mengembalikan rekomendasi null (tidak dapat diseduh)',
        () async {
      final res = await engine.resolve(
        species: 'Arabica',
        roast: 'Green',
        qualityProfile: QualityProfile.low,
      );

      expect(res.recommendation, isNull);
      expect(res.ref, isNull);
      expect(res.alternatives, isEmpty);
    });

    test('Arabica Light High mengembalikan V60 dengan parameter yang tepat',
        () async {
      final res = await engine.resolve(
        species: 'Arabica',
        roast: 'Light',
        qualityProfile: QualityProfile.high,
      );

      expect(res.recommendation, isNotNull);
      expect(res.recommendation!.methodTitle, contains('Pour Over'));
      expect(res.recommendation!.ratio, '1:15');
      expect(res.recommendation!.tempC, '92°C');
      expect(res.ref?.methodId, 'M001');
      expect(res.ref?.recipeId, 'R001');
    });
  });
}
