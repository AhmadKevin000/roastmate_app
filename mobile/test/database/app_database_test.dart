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

    test('onCreate membentuk tepat 6 tabel (§2)', () async {
      final db = await AppDatabase.instance.database;
      expect(await tableNames(db), {
        'brew_methods',
        'brew_recipes',
        'analyses',
        'analysis_defects',
        'recommendations',
        'meta',
      });
    });

    test('onCreate membentuk tepat 5 index (§10)', () async {
      final db = await AppDatabase.instance.database;
      expect(await indexNames(db), {
        'idx_recipes_method',
        'idx_recipes_lookup',
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
  });
}
