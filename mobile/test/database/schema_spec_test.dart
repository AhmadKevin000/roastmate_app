// Uji kepatuhan skema terhadap ketentuan kanonik `docs/DATABASE_SCHEMA.md`.
//
// Prinsip: setiap ekspektasi diambil dari DOKUMEN, bukan dari kode skema.
// Bila `schema.dart` menyimpang dari dokumen, test ini HARUS gagal.
//
// Referensi bagian dokumen ditulis di tiap grup/`reason`.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';

/// Membuka database in-memory lalu menjalankan DDL kanonik (schema.dart),
/// dengan penegakan foreign key seperti `AppDatabase.onConfigure`.
Future<Database> openSchemaDatabase() async {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: kSchemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final stmt in kCreateTableStatements) {
          await db.execute(stmt);
        }
        for (final stmt in kCreateIndexStatements) {
          await db.execute(stmt);
        }
      },
    ),
  );
}

Future<Set<String>> tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

Future<Set<String>> indexNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index' "
    "AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

/// PRAGMA table_info → map nama kolom → baris info.
Future<Map<String, Map<String, Object?>>> columnsOf(
  Database db,
  String table,
) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return {
    for (final r in rows) r['name'] as String: r,
  };
}

/// Menyisipkan satu metode valid; mengembalikan method_id.
Future<String> insertMethod(
  Database db, {
  String id = 'M001',
  String type = 'pour_over',
}) async {
  await db.insert('brew_methods', {
    'method_id': id,
    'method_name': 'Metode $id',
    'method_type': type,
    'description': null,
  });
  return id;
}

/// Menyisipkan satu resep valid (bergantung pada [methodId]).
Future<String> insertRecipe(
  Database db, {
  required String methodId,
  String id = 'R001',
  Map<String, Object?> overrides = const {},
}) async {
  final row = <String, Object?>{
    'recipe_id': id,
    'method_id': methodId,
    'species': 'Arabica',
    'quality_profile': 'High',
    'roast_context': 'Light/Medium',
    'dose_g': 15.0,
    'water_volume_ml': 225,
    'grind_size': 'Medium-Fine',
    'temperature_c': 92,
    'brewing_time_s': 165,
    'source': 'BR001',
    'is_default': 1,
    'steps': '[]',
    'notes': null,
  }..addAll(overrides);
  await db.insert('brew_recipes', row);
  return id;
}

/// Menyisipkan satu analisis valid; mengembalikan id.
Future<int> insertAnalysis(
  Database db, {
  Map<String, Object?> overrides = const {},
}) async {
  final row = <String, Object?>{
    'created_at': '2026-01-01T00:00:00Z',
    'image_path': null,
    'annotated_image_path': null,
    'species': 'Arabica',
    'roast': 'Medium',
    'roast_confidence': 0.9,
    'roast_distribution': null,
    'visible_beans': 24,
    'defect_rate': 0.1,
    'shape_uniformity': 0.8,
    'size_uniformity': 0.8,
    'roast_uniformity': 0.9,
    'quality_score': 82,
    'quality_profile': 'High',
  }..addAll(overrides);
  return db.insert('analyses', row);
}

void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await openSchemaDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ==========================================================================
  // §2 Daftar Tabel
  // ==========================================================================
  group('§2 Daftar tabel', () {
    test('berisi tepat 6 tabel sesuai dokumen', () async {
      const expected = {
        'brew_methods',
        'brew_recipes',
        'analyses',
        'analysis_defects',
        'recommendations',
        'meta',
      };
      expect(await tableNames(db), expected);
    });
  });

  // ==========================================================================
  // §10 Index
  // ==========================================================================
  group('§10 Index', () {
    test('berisi tepat 5 index dengan nama kanonik', () async {
      const expected = {
        'idx_recipes_method',
        'idx_recipes_lookup',
        'idx_analyses_created',
        'idx_defects_analysis',
        'idx_recommendations_analysis',
      };
      expect(await indexNames(db), expected);
    });
  });

  // ==========================================================================
  // §11 Enum & Nilai Sah — CHECK constraint
  // ==========================================================================
  group('§11 CHECK method_type (brew_methods)', () {
    for (final type in const [
      'pour_over',
      'immersion',
      'hybrid',
      'pressure',
      'espresso',
    ]) {
      test('menerima method_type "$type"', () async {
        await insertMethod(db, type: type);
        final rows = await db.query('brew_methods');
        expect(rows.single['method_type'], type);
      });
    }

    test('menolak method_type di luar daftar', () async {
      expect(
        () => insertMethod(db, type: 'cold_brew'),
        throwsA(isA<DatabaseException>()),
        reason: 'method_type harus dibatasi CHECK sesuai §11',
      );
    });
  });

  group('§5/§11 CHECK brew_recipes', () {
    setUp(() async {
      await insertMethod(db);
    });

    for (final species in const ['Arabica', 'Robusta', 'Mixed']) {
      test('menerima species "$species"', () async {
        await insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'species': species},
        );
      });
    }

    test('menolak species di luar daftar', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'species': 'Liberica'},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    for (final profile in const ['High', 'Medium', 'Low']) {
      test('menerima quality_profile "$profile"', () async {
        await insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'quality_profile': profile},
        );
      });
    }

    test('menolak quality_profile di luar daftar', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'quality_profile': 'Very High'},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    for (final ctx in const [
      'Green',
      'Light',
      'Medium',
      'Dark',
      'Light/Medium',
      'Medium/Dark',
    ]) {
      test('menerima roast_context "$ctx"', () async {
        await insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'roast_context': ctx},
        );
      });
    }

    test('menolak roast_context di luar daftar', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'roast_context': 'Extra Dark'},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    for (final grind in const [
      'Espresso',
      'Fine',
      'Medium-Fine',
      'Medium',
      'Medium-Coarse',
      'Coarse',
    ]) {
      test('menerima grind_size "$grind"', () async {
        await insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'grind_size': grind},
        );
      });
    }

    test('menolak grind_size di luar daftar', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'grind_size': 'Powder'},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('menolak is_default selain 0/1', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'is_default': 2},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('source NOT NULL (§5)', () async {
      expect(
        () => insertRecipe(
          db,
          methodId: 'M001',
          overrides: {'source': null},
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('§6/§11 CHECK analyses', () {
    test('menolak species di luar daftar', () async {
      expect(
        () => insertAnalysis(db, overrides: {'species': 'Liberica'}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('menolak roast di luar daftar', () async {
      expect(
        () => insertAnalysis(db, overrides: {'roast': 'Extra Dark'}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('menolak quality_profile di luar daftar', () async {
      expect(
        () => insertAnalysis(db, overrides: {'quality_profile': 'Very High'}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('menerima species/roast/quality_profile NULL (§6 nullable)', () async {
      final id = await insertAnalysis(db, overrides: {
        'species': null,
        'roast': null,
        'quality_profile': null,
      });
      expect(id, greaterThan(0));
    });
  });

  group('§7/§11 CHECK analysis_defects.defect_class', () {
    late int analysisId;

    setUp(() async {
      analysisId = await insertAnalysis(db);
    });

    for (final cls in const [
      'Healthy',
      'Broken',
      'Insect Damage',
      'Quaker',
      'Scorched',
      'Foreign Matter',
    ]) {
      test('menerima defect_class "$cls"', () async {
        await db.insert('analysis_defects', {
          'analysis_id': analysisId,
          'defect_class': cls,
          'count': 1,
        });
      });
    }

    test('menolak defect_class di luar 6 kelas final', () async {
      expect(
        () => db.insert('analysis_defects', {
          'analysis_id': analysisId,
          'defect_class': 'Burnt',
          'count': 1,
        }),
        throwsA(isA<DatabaseException>()),
        reason: 'D-03: burnt/mold/under EXCLUDED dari taxonomy final',
      );
    });
  });

  // ==========================================================================
  // §5/§7 Default & NOT NULL
  // ==========================================================================
  group('§5/§7 DEFAULT', () {
    test('brew_recipes.is_default default 0', () async {
      await insertMethod(db);
      await db.insert('brew_recipes', {
        'recipe_id': 'R009',
        'method_id': 'M001',
        'species': 'Arabica',
        'quality_profile': 'High',
        'roast_context': 'Medium',
        'source': 'BR002',
      });
      final row = (await db.query(
        'brew_recipes',
        where: 'recipe_id = ?',
        whereArgs: ['R009'],
      ))
          .single;
      expect(row['is_default'], 0);
    });

    test('analysis_defects.count default 0', () async {
      final analysisId = await insertAnalysis(db);
      await db.insert('analysis_defects', {
        'analysis_id': analysisId,
        'defect_class': 'Healthy',
      });
      final row = (await db.query(
        'analysis_defects',
        where: 'analysis_id = ?',
        whereArgs: [analysisId],
      ))
          .single;
      expect(row['count'], 0);
    });

    test('analyses.created_at NOT NULL', () async {
      expect(
        () => insertAnalysis(db, overrides: {'created_at': null}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('meta.value NOT NULL', () async {
      expect(
        () => db.insert('meta', {'key': 'k', 'value': null}),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  // ==========================================================================
  // §5/§8/§14 Foreign key & integritas
  // ==========================================================================
  group('§5/§8/§14 Foreign key', () {
    test('brew_recipes.method_id harus ada di brew_methods', () async {
      expect(
        () => insertRecipe(db, methodId: 'M999'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('recommendations.primary_method_id harus valid', () async {
      final analysisId = await insertAnalysis(db);
      expect(
        () => db.insert('recommendations', {
          'analysis_id': analysisId,
          'primary_method_id': 'M999',
          'primary_recipe_id': 'R999',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('recommendations.primary_recipe_id harus valid', () async {
      await insertMethod(db);
      final analysisId = await insertAnalysis(db);
      expect(
        () => db.insert('recommendations', {
          'analysis_id': analysisId,
          'primary_method_id': 'M001',
          'primary_recipe_id': 'R999',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('menghapus analyses menghapus analysis_defects (CASCADE)', () async {
      final analysisId = await insertAnalysis(db);
      await db.insert('analysis_defects', {
        'analysis_id': analysisId,
        'defect_class': 'Healthy',
        'count': 3,
      });

      await db.delete('analyses', where: 'id = ?', whereArgs: [analysisId]);

      final rows = await db.query('analysis_defects');
      expect(rows, isEmpty, reason: '§14.5 ON DELETE CASCADE');
    });

    test('menghapus analyses menghapus recommendations (CASCADE)', () async {
      await insertMethod(db);
      await insertRecipe(db, methodId: 'M001');
      final analysisId = await insertAnalysis(db);
      await db.insert('recommendations', {
        'analysis_id': analysisId,
        'primary_method_id': 'M001',
        'primary_recipe_id': 'R001',
      });

      await db.delete('analyses', where: 'id = ?', whereArgs: [analysisId]);

      final rows = await db.query('recommendations');
      expect(rows, isEmpty, reason: '§14.5 ON DELETE CASCADE');
    });
  });

  // ==========================================================================
  // §7/§8/§14 UNIQUE
  // ==========================================================================
  group('§7/§8/§14 UNIQUE', () {
    test('analysis_defects unik per (analysis_id, defect_class)', () async {
      final analysisId = await insertAnalysis(db);
      await db.insert('analysis_defects', {
        'analysis_id': analysisId,
        'defect_class': 'Quaker',
        'count': 1,
      });
      expect(
        () => db.insert('analysis_defects', {
          'analysis_id': analysisId,
          'defect_class': 'Quaker',
          'count': 2,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('recommendations unik per analysis_id', () async {
      await insertMethod(db);
      await insertRecipe(db, methodId: 'M001');
      final analysisId = await insertAnalysis(db);
      await db.insert('recommendations', {
        'analysis_id': analysisId,
        'primary_method_id': 'M001',
        'primary_recipe_id': 'R001',
      });
      expect(
        () => db.insert('recommendations', {
          'analysis_id': analysisId,
          'primary_method_id': 'M001',
          'primary_recipe_id': 'R001',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('meta.key unik (PK)', () async {
      await db.insert('meta', {'key': 'schema_version', 'value': '1'});
      expect(
        () => db.insert('meta', {'key': 'schema_version', 'value': '2'}),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  // ==========================================================================
  // §6/§15 Nilai turunan TIDAK disimpan
  // ==========================================================================
  group('§6/§15 Nilai turunan tidak disimpan', () {
    test('analyses tidak memiliki kolom grade', () async {
      final cols = await columnsOf(db, 'analyses');
      expect(cols.containsKey('grade'), isFalse,
          reason: '§6: grade diturunkan dari quality_profile (D-02)');
    });

    test('analyses tidak memiliki kolom status', () async {
      final cols = await columnsOf(db, 'analyses');
      expect(cols.containsKey('status'), isFalse,
          reason: '§6/§15: status uncertain diturunkan dari roast_confidence');
    });

    test('brew_recipes tidak menyimpan rasio', () async {
      final cols = await columnsOf(db, 'brew_recipes');
      expect(cols.containsKey('ratio'), isFalse,
          reason: '§5: rasio dihitung water_volume_ml / dose_g');
    });
  });

  // ==========================================================================
  // D-12 Strategi PK
  // ==========================================================================
  group('D-12 Strategi primary key', () {
    test('knowledge base memakai PK TEXT', () async {
      final methods = await columnsOf(db, 'brew_methods');
      expect(methods['method_id']!['pk'], 1);
      expect((methods['method_id']!['type'] as String).toUpperCase(),
          contains('TEXT'));

      final recipes = await columnsOf(db, 'brew_recipes');
      expect(recipes['recipe_id']!['pk'], 1);
      expect((recipes['recipe_id']!['type'] as String).toUpperCase(),
          contains('TEXT'));
    });

    test('riwayat memakai PK INTEGER AUTOINCREMENT', () async {
      final analyses = await columnsOf(db, 'analyses');
      expect(analyses['id']!['pk'], 1);
      expect((analyses['id']!['type'] as String).toUpperCase(),
          contains('INTEGER'));
    });
  });

  // ==========================================================================
  // §6 Kolom analyses sesuai dokumen
  // ==========================================================================
  group('§6 Kolom analyses sesuai dokumen', () {
    test('memuat tepat kolom yang didokumentasikan', () async {
      final cols = (await columnsOf(db, 'analyses')).keys.toSet();
      expect(cols, {
        'id',
        'created_at',
        'image_path',
        'annotated_image_path',
        'species',
        'roast',
        'roast_confidence',
        'roast_distribution',
        'visible_beans',
        'defect_rate',
        'shape_uniformity',
        'size_uniformity',
        'roast_uniformity',
        'quality_score',
        'quality_profile',
      });
    });
  });

  // ==========================================================================
  // §5 Kolom brew_recipes sesuai dokumen (termasuk notes — D-18)
  // ==========================================================================
  group('§5 Kolom brew_recipes sesuai dokumen', () {
    test('memuat tepat kolom yang didokumentasikan', () async {
      final cols = (await columnsOf(db, 'brew_recipes')).keys.toSet();
      expect(cols, {
        'recipe_id',
        'method_id',
        'species',
        'quality_profile',
        'roast_context',
        'dose_g',
        'water_volume_ml',
        'grind_size',
        'temperature_c',
        'brewing_time_s',
        'source',
        'is_default',
        'steps',
        'notes',
      });
    });
  });
}
