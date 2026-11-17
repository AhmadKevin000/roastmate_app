// Uji integrasi `AppDatabase` — memastikan jalur buka database nyata berjalan:
// `onCreate` membentuk skema, `meta` terisi, dan seeding idempoten.
//
// Ekspektasi mengacu ke `docs/DATABASE_SCHEMA.md` (§2, §9, §12, §13), bukan
// disesuaikan ke implementasi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/app_database.dart';
import 'package:pbl_sem5/core/database/schema.dart';

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

Future<Map<String, String>> metaValues(Database db) async {
  final rows = await db.query('meta');
  return {
    for (final r in rows) r['key'] as String: r['value'] as String,
  };
}

void main() {
  // Diperlukan agar `rootBundle` (dipakai seeder) tersedia di lingkungan test.
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase', () {
    setUp(() async {
      // Pastikan tiap test mulai dari database bersih.
      await AppDatabase.instance.close();
      final path = p.join(await getDatabasesPath(), kDatabaseName);
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    });

    tearDown(() async {
      await AppDatabase.instance.close();
    });

    test('onCreate membentuk tepat 9 tabel (§2)', () async {
      final db = await AppDatabase.instance.database;
      expect(await tableNames(db), {
        'brew_methods',
        'brew_tools',
        'brew_method_tools',
        'brew_recipes',
        'analyses',
        'analysis_defects',
        'recommendations',
        'user_brew_recipes',
        'meta',
      });
    });

    test('onCreate membentuk tepat 6 index (§10)', () async {
      final db = await AppDatabase.instance.database;
      expect(await indexNames(db), {
        'idx_recipes_method',
        'idx_recipes_lookup',
        'idx_method_tools_tool',
        'idx_analyses_created',
        'idx_defects_analysis',
        'idx_recommendations_analysis',
      });
    });

    test('meta berisi schema_version sesuai kSchemaVersion (§12)', () async {
      final db = await AppDatabase.instance.database;
      final meta = await metaValues(db);
      expect(meta[kMetaSchemaVersion], kSchemaVersion.toString());
    });

    test('meta berisi kb_version dari seed (§12/§13)', () async {
      final db = await AppDatabase.instance.database;
      final meta = await metaValues(db);
      expect(meta[kMetaKbVersion], isNotNull);
      expect(meta[kMetaKbVersion], isNotEmpty);
    });

    test('foreign_keys aktif saat koneksi dibuka (§14)', () async {
      final db = await AppDatabase.instance.database;
      final rows = await db.rawQuery('PRAGMA foreign_keys');
      expect(rows.single.values.first, 1);
    });

    test('seeding idempoten: tidak menggandakan data (§13)', () async {
      final db = await AppDatabase.instance.database;

      final before = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM brew_methods'),
      );

      // Jalankan ulang seeding; tidak boleh menambah/mengubah apa pun.
      await AppDatabase.instance.close();
      final db2 = await AppDatabase.instance.database;
      final after = Sqflite.firstIntValue(
        await db2.rawQuery('SELECT COUNT(*) FROM brew_methods'),
      );

      expect(after, before);
    });

    test('reseed KB saat kb_version asset naik (§13)', () async {
      final db = await AppDatabase.instance.database;

      // Simulasikan DB dev lama: `meta.kb_version` masih 1.1 (era 3 resep),
      // padahal asset sekarang 1.2 (14 resep).
      await db.update(
        'meta',
        <String, Object?>{'value': '1.1'},
        where: 'key = ?',
        whereArgs: <Object?>[kMetaKbVersion],
      );

      await AppDatabase.instance.close();
      final db2 = await AppDatabase.instance.database;

      final recipeCount = Sqflite.firstIntValue(
        await db2.rawQuery('SELECT COUNT(*) FROM brew_recipes'),
      );
      expect(recipeCount, 14);
      expect((await metaValues(db2))[kMetaKbVersion], '1.2');
    });

    test('migrasi v1 → v2 menambah kolom analyses.name (D-20)', () async {
      final path = p.join(await getDatabasesPath(), kDatabaseName);

      // Bangun database skema v1 (tanpa kolom `name`) seperti instalasi lama.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE analyses (
                id                    INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at            TEXT NOT NULL,
                image_path            TEXT,
                annotated_image_path  TEXT,
                species               TEXT,
                roast                 TEXT,
                roast_confidence      REAL,
                roast_distribution    TEXT,
                visible_beans         INTEGER,
                defect_rate           REAL,
                shape_uniformity      REAL,
                size_uniformity       REAL,
                roast_uniformity      REAL,
                quality_score         INTEGER,
                quality_profile       TEXT
              )
            ''');
            // Instalasi v1 lama juga punya tabel knowledge base; dibutuhkan
            // agar migrasi v2 → v3 (ALTER brew_methods + reseed) berjalan.
            await db.execute('''
              CREATE TABLE brew_methods (
                method_id    TEXT PRIMARY KEY,
                method_name  TEXT NOT NULL,
                method_type  TEXT NOT NULL,
                description  TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE brew_recipes (
                recipe_id        TEXT PRIMARY KEY,
                method_id        TEXT NOT NULL REFERENCES brew_methods(method_id),
                species          TEXT NOT NULL,
                quality_profile  TEXT NOT NULL,
                roast_context    TEXT NOT NULL,
                dose_g           REAL,
                water_volume_ml  INTEGER,
                grind_size       TEXT,
                temperature_c    INTEGER,
                brewing_time_s   INTEGER,
                source           TEXT NOT NULL,
                is_default       INTEGER NOT NULL DEFAULT 0,
                steps            TEXT,
                notes            TEXT
              )
            ''');
            await db.execute('''CREATE TABLE meta (
              key   TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )''');
            await db.insert('meta', {
              'key': kMetaSchemaVersion,
              'value': '1',
            });
          },
        ),
      );
      await v1.close();

      // Buka dengan versi skema terkini: onUpgrade harus menjalankan migrasi.
      final db = await AppDatabase.instance.database;
      final columns = (await db.rawQuery('PRAGMA table_info(analyses)'))
          .map((row) => row['name'] as String)
          .toSet();

      expect(columns, contains('name'));
      expect((await metaValues(db))[kMetaSchemaVersion], kSchemaVersion.toString());
    });

    test('migrasi v3 → v4 menambah tabel user_brew_recipes, data v3 utuh', () async {
      final path = p.join(await getDatabasesPath(), kDatabaseName);

      // Bangun database skema v3 seperti instalasi sebelum Plan 4:
      // seluruh DDL v4 kecuali tabel user_brew_recipes.
      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            for (final stmt in kCreateTableStatements) {
              if (stmt.contains('user_brew_recipes')) continue;
              await db.execute(stmt);
            }
            // Data v3 yang harus tetap utuh setelah migrasi.
            await db.insert('brew_methods', {
              'method_id': 'M001',
              'method_name': 'V60 / Pour Over',
              'method_type': 'pour_over',
            });
            await db.insert('analyses', {
              'created_at': '2026-01-01T00:00:00Z',
              'batch_name': 'Batch Uji Migrasi',
              'species': 'Arabica',
            });
            await db.insert('meta', {
              'key': kMetaSchemaVersion,
              'value': '3',
            });
          },
        ),
      );
      await v3.close();

      // Buka dengan versi skema terkini: onUpgrade menjalankan v3 → v4.
      final db = await AppDatabase.instance.database;
      expect(await tableNames(db), contains('user_brew_recipes'));

      // Data v3 utuh (riwayat tak disentuh migrasi/seeder).
      final analyses = await db.query(
        'analyses',
        where: 'batch_name = ?',
        whereArgs: ['Batch Uji Migrasi'],
      );
      expect(analyses, hasLength(1));
      final methods = await db.query(
        'brew_methods',
        where: 'method_id = ?',
        whereArgs: ['M001'],
      );
      expect(methods, hasLength(1));
      expect((await metaValues(db))[kMetaSchemaVersion],
          kSchemaVersion.toString());
    });

    test('migrasi v4 → v5 menambal kolom analyses legacy (data utuh)',
        () async {
      final path = p.join(await getDatabasesPath(), kDatabaseName);

      // Simulasi DB v4 era dev/bon: versi file 4, tabel lengkap, tetapi
      // `analyses` tanpa kolom identitas (name, batch_label, batch_name,
      // model_version) — persis kondisi device yang crash di alur scan.
      const legacyAnalyses = '''
        CREATE TABLE analyses (
          id                    INTEGER PRIMARY KEY AUTOINCREMENT,
          created_at            TEXT NOT NULL,
          image_path            TEXT,
          annotated_image_path  TEXT,
          species               TEXT CHECK (species IN ('Arabica','Robusta','Liberika','Mixed')),
          roast                 TEXT CHECK (roast IN ('Green','Light','Medium','Dark')),
          roast_confidence      REAL,
          roast_distribution    TEXT,
          visible_beans         INTEGER,
          defect_rate           REAL,
          shape_uniformity      REAL,
          size_uniformity       REAL,
          roast_uniformity      REAL,
          quality_score         INTEGER,
          quality_profile       TEXT CHECK (quality_profile IN ('High','Medium','Low'))
        )
      ''';
      final v4 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, version) async {
            for (final stmt in kCreateTableStatements) {
              if (stmt.contains('CREATE TABLE analyses')) continue;
              await db.execute(stmt);
            }
            await db.execute(legacyAnalyses);
            await db.insert('analyses', {
              'created_at': '2026-11-01T00:00:00Z',
              'image_path': '/cache/legacy.jpg',
              'species': 'Liberika',
              'roast': 'Light',
            });
            await db.insert('meta', {
              'key': kMetaSchemaVersion,
              'value': '4',
            });
          },
        ),
      );
      await v4.close();

      final db = await AppDatabase.instance.database;
      final cols = (await db.rawQuery('PRAGMA table_info(analyses)'))
          .map((r) => r['name'] as String)
          .toSet();
      expect(
        cols,
        containsAll({
          'name',
          'batch_label',
          'batch_name',
          'model_version',
          'image_path',
          'annotated_image_path',
        }),
      );

      // Baris legacy utuh (INSERT alur scan kini bisa lewat).
      final rows = await db.query(
        'analyses',
        where: 'species = ?',
        whereArgs: ['Liberika'],
      );
      expect(rows, hasLength(1));
      expect(rows.single['image_path'], '/cache/legacy.jpg');
      expect((await metaValues(db))[kMetaSchemaVersion],
          kSchemaVersion.toString());
    });
  });
}
