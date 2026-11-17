// Uji `RecommendationResolver` — ke-12 kombinasi species × roast menghasilkan
// `RecommendationRef` valid (resep default KB + reason template + alternatif
// metode), dan insert `recommendations` lolos FK ke `brew_methods`/`brew_recipes`.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'
    show Database, databaseFactory, inMemoryDatabasePath, openDatabase;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/knowledge_base_seeder.dart';
import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_repository.dart';
import 'package:pbl_sem5/features/analysis/data/sources/recommendation_resolver.dart';
import 'package:pbl_sem5/features/analysis/data/sources/reason_template_source.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late RecommendationResolver resolver;
  late AnalysisRepository analysisRepo;

  // Fixture hasil analisis sederhana (konteks species × roast-nya diabaikan
  // oleh resolver; yang penting baris analyses sah).
  final fixture = InspectionResult(
    batchLabel: 'Batch #T',
    batchName: 'Template Test',
    analyzedAgo: '-',
    qualityScore: 80,
    visibleBeans: 20,
    defectCounts: const {DefectClass.normal: 18, DefectClass.quaker: 2},
    species: 'Arabica',
    roast: 'Light',
    summaryText: '',
    alternatives: const [],
    detections: const [],
    modelVersion: 'Template v1.0',
  );

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: kSchemaVersion,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        for (final stmt in kCreateTableStatements) {
          await d.execute(stmt);
        }
        for (final stmt in kCreateIndexStatements) {
          await d.execute(stmt);
        }
      },
    );
    // Seed KB dari asset nyata (14 resep — Plan 1).
    await KnowledgeBaseSeeder(db).seedIfEmpty();

    final brew = BrewingRepositoryImpl(database: db);
    resolver = RecommendationResolver(brew, ReasonTemplateSource());
    analysisRepo = AnalysisRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('12 kombinasi species × roast → ref valid & insert lolos FK', () async {
    const combinations = {
      'Arabica': ['Light', 'Medium', 'Dark'],
      'Robusta': ['Light', 'Medium', 'Dark'],
      'Liberika': ['Light', 'Medium', 'Dark'],
      'Mixed': ['Light', 'Medium', 'Dark'],
    };

    for (final entry in combinations.entries) {
      for (final roast in entry.value) {
        final ref =
            await resolver.resolve(species: entry.key, roast: roast);
        expect(ref, isNotNull, reason: '${entry.key}|$roast');

        // recipeId harus merujuk resep default yang benar-benar ada di KB.
        final recipeRows = await db.query(
          'brew_recipes',
          where: 'recipe_id = ?',
          whereArgs: [ref!.recipeId],
        );
        expect(recipeRows, hasLength(1), reason: '${entry.key}|$roast');
        expect(
          recipeRows.single['species'] as String,
          entry.key,
          reason: '${entry.key}|$roast',
        );

        // reason dari template — non-kosong.
        expect(ref.reason.trim(), isNotEmpty);

        // Insert rekomendasi: FK primary_method_id/primary_recipe_id lolos.
        final analysisId = await analysisRepo.insertResult(
          fixture,
          createdAt: DateTime(2025, 1, 1),
          recommendation: ref,
        );
        final recRows = await db.query(
          'recommendations',
          where: 'analysis_id = ?',
          whereArgs: [analysisId],
        );
        expect(recRows, hasLength(1), reason: '${entry.key}|$roast');
      }
    }
  });

  test('kombinasi tanpa resep default → null (UI fallback)', () async {
    final ref = await resolver.resolve(species: 'Arabica', roast: 'Green');
    expect(ref, isNull);
  });
}
