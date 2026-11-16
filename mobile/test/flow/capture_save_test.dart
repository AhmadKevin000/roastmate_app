// Uji orkestrasi inti alur capture (Plan 2): template acak dari asset nyata
// → `RecommendationResolver` (KB nyata) → `AnalysisRepository.insertResult`
// ke SQLite in-memory → kolom `analyses` + `analysis_defects` +
// `recommendations` konsisten, lalu `updateImagePath` (simulasi sukses
// upload Cloudinary).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'
    show Database, databaseFactory, inMemoryDatabasePath, openDatabase;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/knowledge_base_seeder.dart';
import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_repository.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_template_source.dart';
import 'package:pbl_sem5/features/analysis/data/sources/reason_template_source.dart';
import 'package:pbl_sem5/features/analysis/data/sources/recommendation_resolver.dart';
import 'package:pbl_sem5/features/analysis/domain/analysis_result_builder.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';
import 'package:pbl_sem5/shared/enums/quality_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late AnalysisRepository repo;

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
    await KnowledgeBaseSeeder(db).seedIfEmpty();
    repo = AnalysisRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('capture template menyimpan kolom AC-01 + defects + rekomendasi',
      () async {
    final source = AnalysisTemplateSource();
    final template = source.pick(await source.loadAll(), Random(7));
    final batchLabel = await repo.nextBatchLabel();
    final result = buildResultFromTemplate(template, 'Gayo Natural', batchLabel);

    final resolver = RecommendationResolver(
      BrewingRepositoryImpl(database: db),
      ReasonTemplateSource(),
    );
    final recommendation = await resolver.resolve(
      species: template.species,
      roast: template.roast,
    );
    expect(recommendation, isNotNull,
        reason: 'KB harus punya resep default untuk ${template.species}|${template.roast}');

    const localPath = '/tmp/roastmate_capture_test.jpg';
    final analysisId = await repo.insertResult(
      result,
      createdAt: DateTime(2025, 1, 1),
      imagePath: localPath,
      recommendation: recommendation,
    );

    // AC-01: kolom template tersimpan.
    final row = (await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
    )).single;
    expect(row['name'], 'Gayo Natural');
    expect(row['batch_name'], 'Gayo Natural');
    expect(row['batch_label'], batchLabel);
    expect(row['species'], template.species);
    expect(row['roast'], template.roast);
    expect(row['model_version'], 'template-v1');
    expect(row['visible_beans'], template.visibleBeans);
    expect(row['quality_score'], result.qualityScore);
    // Kolom menyimpan nama kanonik Title Case (DATABASE_SCHEMA §11), bukan
    // nama enum Dart.
    expect(
      row['quality_profile'],
      switch (result.qualityProfile) {
        QualityProfile.high => 'High',
        QualityProfile.medium => 'Medium',
        QualityProfile.low => 'Low',
      },
    );
    expect((row['defect_rate'] as num).toDouble(),
        closeTo(result.defectRate, 1e-9));
    expect(row['image_path'], localPath);
    expect(row['roast_confidence'], template.roastConfidence);
    expect(row['shape_uniformity'], template.shapeUniformity);
    expect(row['size_uniformity'], template.sizeUniformity);
    expect(row['roast_uniformity'], template.roastUniformity);

    // AC-03: defects ≤ 4 kelas, Σcounts == visible_beans.
    final defectRows = await db.query(
      'analysis_defects',
      where: 'analysis_id = ?',
      whereArgs: [analysisId],
    );
    expect(defectRows.length, lessThanOrEqualTo(4));
    expect(
      defectRows.fold<int>(0, (s, r) => s + (r['count'] as int)),
      template.visibleBeans,
    );

    // Rekomendasi + reason tersimpan (FK valid).
    final recRow = (await db.query(
      'recommendations',
      where: 'analysis_id = ?',
      whereArgs: [analysisId],
    )).single;
    expect(recRow['primary_recipe_id'], recommendation!.recipeId);
    expect((recRow['reason'] as String).trim(), isNotEmpty);

    // Simulasi sukses upload Cloudinary → image_path jadi secure URL.
    const secureUrl =
        'https://res.cloudinary.com/demo/image/upload/v1/capture.jpg';
    await repo.updateImagePath(analysisId, secureUrl);
    final after = (await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
      columns: ['image_path'],
    )).single;
    expect(after['image_path'], secureUrl);
  });

  test('nextBatchLabel berurutan mengikuti jumlah baris', () async {
    expect(await repo.nextBatchLabel(), 'Batch #001');

    final source = AnalysisTemplateSource();
    final template = source.pick(await source.loadAll(), Random(1));
    await repo.insertResult(
      buildResultFromTemplate(template, 'A', 'Batch #001'),
      createdAt: DateTime(2025, 1, 1),
    );
    expect(await repo.nextBatchLabel(), 'Batch #002');
  });
}
