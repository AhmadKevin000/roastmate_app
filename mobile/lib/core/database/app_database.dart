import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'knowledge_base_seeder.dart';
import 'schema.dart';

/// Akses tunggal ke database SQLite lokal.
///
/// Singleton sederhana (tanpa state management). Panggil
/// `AppDatabase.instance.database` untuk membuka/mengakses database.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  /// Database yang sudah dibuka (lazy).
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), kDatabaseName);
    final db = await openDatabase(
      path,
      version: kSchemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Cek seed KB tiap kali buka: no-op bila versi sama, reseed bila
    // `kb_version` asset naik (DB dev lama tetap terselamatkan).
    await KnowledgeBaseSeeder(db).seedIfEmpty();
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final stmt in kCreateTableStatements) {
      batch.execute(stmt);
    }
    for (final stmt in kCreateIndexStatements) {
      batch.execute(stmt);
    }
    await batch.commit(noResult: true);

    await db.insert('meta', <String, Object?>{
      'key': kMetaSchemaVersion,
      'value': version.toString(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi bertingkat: jalankan langkah dari oldVersion sampai newVersion.
    final batch = db.batch();

    // v1 → v2: kolom identitas batch & provenance model (D-19).
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE analyses ADD COLUMN name TEXT');
      batch.execute('ALTER TABLE analyses ADD COLUMN batch_label TEXT');
      batch.execute('ALTER TABLE analyses ADD COLUMN batch_name TEXT');
      batch.execute('ALTER TABLE analyses ADD COLUMN model_version TEXT');
    }

    // v2 → v3: tabel brew_tools, brew_method_tools, kolom visual di brew_methods.
    if (oldVersion < 3) {
      batch.execute('ALTER TABLE brew_methods ADD COLUMN subtitle TEXT');
      batch.execute('ALTER TABLE brew_methods ADD COLUMN image_asset TEXT');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS brew_tools (
          tool_id      TEXT PRIMARY KEY,
          tool_name    TEXT NOT NULL,
          category     TEXT,
          image_asset  TEXT,
          description  TEXT
        )
      ''');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS brew_method_tools (
          method_id    TEXT NOT NULL REFERENCES brew_methods(method_id) ON DELETE CASCADE,
          tool_id      TEXT NOT NULL REFERENCES brew_tools(tool_id) ON DELETE CASCADE,
          is_required  INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
          notes        TEXT,
          PRIMARY KEY (method_id, tool_id)
        )
      ''');
      batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_method_tools_tool ON brew_method_tools(tool_id)',
      );
    }

    // v3 → v4: tabel user_brew_recipes (resep user — di luar KB/reseed).
    if (oldVersion < 4) {
      batch.execute('''
        CREATE TABLE IF NOT EXISTS user_brew_recipes (
          recipe_id        TEXT PRIMARY KEY,
          name             TEXT NOT NULL,
          method_id        TEXT NOT NULL REFERENCES brew_methods(method_id),
          species          TEXT NOT NULL CHECK (species IN
                           ('Arabica','Robusta','Liberika','Mixed')),
          quality_profile  TEXT NOT NULL CHECK (quality_profile IN ('High','Medium','Low')),
          roast_context    TEXT NOT NULL CHECK (roast_context IN
                           ('Green','Light','Medium','Dark','Light/Medium','Medium/Dark')),
          dose_g           REAL,
          water_volume_ml  INTEGER,
          grind_size       TEXT CHECK (grind_size IN
                           ('Espresso','Fine','Medium-Fine','Medium','Medium-Coarse','Coarse')),
          temperature_c    INTEGER,
          brewing_time_s   INTEGER,
          notes            TEXT,
          created_at       TEXT NOT NULL
        )
      ''');
    }

    // v4 → v5: tambal kolom `analyses` untuk DB lama (era dev/bon).
    // Kolom `name` dkk hanya punya migrasi `oldVersion < 2`, dan
    // `image_path`/`annotated_image_path` tak pernah punya migrasi — DB
    // lama dengan versi file ≥ 2 lolos tanpa kolom tersebut (crash INSERT
    // di alur scan). Cek per kolom via PRAGMA, tambah hanya yang hilang
    // (idempoten, aman untuk semua kondisi legacy).
    if (oldVersion < 5) {
      final analysisCols = (await db.rawQuery(
        'PRAGMA table_info(analyses)',
      )).map((r) => r['name'] as String).toSet();
      // Kolom yang sudah dijadwalkan langkah v2 (masih di batch belum
      // commit — tak terlihat oleh PRAGMA di atas): jangan dobel.
      if (oldVersion < 2) {
        analysisCols
          ..add('name')
          ..add('batch_label')
          ..add('batch_name')
          ..add('model_version');
      }
      for (final col in const [
        'name',
        'batch_label',
        'batch_name',
        'model_version',
        'image_path',
        'annotated_image_path',
      ]) {
        if (!analysisCols.contains(col)) {
          batch.execute('ALTER TABLE analyses ADD COLUMN $col TEXT');
        }
      }
    }

    // v5 → v6: rebuild `user_brew_recipes` (SQLite tak bisa mengubah
    // FK/NOT NULL via ALTER): `method_id` menjadi nullable + kolom baru
    // `method_name`, `steps`, `video_url`. Data lama dipindah; `method_name`
    // di-resolve dari join `brew_methods`. `brew_recipes` cukup dapat
    // kolom `video_url`. foreign_keys dimatikan selama rebuild (resep
    // SQLite resmi), diaktifkan lagi setelah commit.
    if (oldVersion < 6) {
      await db.execute('PRAGMA foreign_keys = OFF');
      // Cek bentuk aktual (defensif, idempoten — pola v5): DB dev bisa
      // sudah punya bentuk baru tanpa bump versi.
      final userRecipeCols = (await db.rawQuery(
        'PRAGMA table_info(user_brew_recipes)',
      )).map((r) => r['name'] as String).toSet();
      final brewRecipeCols = (await db.rawQuery(
        'PRAGMA table_info(brew_recipes)',
      )).map((r) => r['name'] as String).toSet();
      if (!userRecipeCols.contains('method_name')) {
        batch.execute('''
          CREATE TABLE user_brew_recipes_v6 (
            recipe_id        TEXT PRIMARY KEY,
            name             TEXT NOT NULL,
            method_id        TEXT REFERENCES brew_methods(method_id) ON DELETE SET NULL,
            method_name      TEXT NOT NULL,
            species          TEXT NOT NULL CHECK (species IN
                             ('Arabica','Robusta','Liberika','Mixed')),
            quality_profile  TEXT NOT NULL CHECK (quality_profile IN ('High','Medium','Low')),
            roast_context    TEXT NOT NULL CHECK (roast_context IN
                             ('Green','Light','Medium','Dark','Light/Medium','Medium/Dark')),
            dose_g           REAL,
            water_volume_ml  INTEGER,
            grind_size       TEXT CHECK (grind_size IN
                             ('Espresso','Fine','Medium-Fine','Medium','Medium-Coarse','Coarse')),
            temperature_c    INTEGER,
            brewing_time_s   INTEGER,
            steps            TEXT,
            video_url        TEXT,
            notes            TEXT,
            created_at       TEXT NOT NULL
          )
        ''');
        batch.execute('''
          INSERT INTO user_brew_recipes_v6 (
            recipe_id, name, method_id, method_name, species, quality_profile,
            roast_context, dose_g, water_volume_ml, grind_size, temperature_c,
            brewing_time_s, steps, video_url, notes, created_at
          )
          SELECT
            recipe_id, name, method_id,
            COALESCE(
              (SELECT m.method_name FROM brew_methods m
                WHERE m.method_id = user_brew_recipes.method_id),
              method_id
            ),
            species, quality_profile, roast_context,
            dose_g, water_volume_ml, grind_size, temperature_c,
            brewing_time_s, NULL, NULL, notes, created_at
          FROM user_brew_recipes
        ''');
        batch.execute('DROP TABLE user_brew_recipes');
        batch.execute(
          'ALTER TABLE user_brew_recipes_v6 RENAME TO user_brew_recipes',
        );
      }
      if (!brewRecipeCols.contains('video_url')) {
        batch.execute('ALTER TABLE brew_recipes ADD COLUMN video_url TEXT');
      }
    }

    // v6 → v7: kolom sync D-29 (guarded idempoten per kolom, pola v5).
    if (oldVersion < 7) {
      Map<String, Set<String>> cols = {};
      for (final table in const [
        'analyses',
        'analysis_defects',
        'recommendations',
        'user_brew_recipes',
      ]) {
        cols[table] = (await db.rawQuery(
          'PRAGMA table_info($table)',
        )).map((r) => r['name'] as String).toSet();
      }
      // analyses & user_brew_recipes: uuid, user_id, sync_status, updated_at.
      // Tabel yang belum ada (DB dev sangat lama) di-skip — dibuat lengkap
      // oleh onCreate di instalasi baru.
      for (final col in const [
        'uuid',
        'user_id',
        'sync_status',
        'updated_at',
      ]) {
        if (cols['analyses']!.isNotEmpty && !cols['analyses']!.contains(col)) {
          batch.execute('ALTER TABLE analyses ADD COLUMN $col TEXT');
        }
        if (cols['user_brew_recipes']!.isNotEmpty &&
            !cols['user_brew_recipes']!.contains(col)) {
          batch.execute('ALTER TABLE user_brew_recipes ADD COLUMN $col TEXT');
        }
      }
      // analysis_defects & recommendations: uuid + sync_status saja.
      for (final col in const ['uuid', 'sync_status']) {
        if (cols['analysis_defects']!.isNotEmpty &&
            !cols['analysis_defects']!.contains(col)) {
          batch.execute('ALTER TABLE analysis_defects ADD COLUMN $col TEXT');
        }
        if (cols['recommendations']!.isNotEmpty &&
            !cols['recommendations']!.contains(col)) {
          batch.execute('ALTER TABLE recommendations ADD COLUMN $col TEXT');
        }
      }
      if (cols['analyses']!.isNotEmpty) {
        batch.execute(
          'CREATE INDEX IF NOT EXISTS idx_analyses_sync ON analyses(sync_status)',
        );
      }
    }

    // v7 → v8: penilaian pribadi user (bintang 1–5 + catatan) pada
    // `analyses`. ALTER guarded idempoten per kolom (pola v5). CHECK rentang
    // 1–5 tidak bisa ditambahkan lewat ALTER; validasi di repository.
    if (oldVersion < 8) {
      final analysisCols = (await db.rawQuery(
        'PRAGMA table_info(analyses)',
      )).map((r) => r['name'] as String).toSet();
      if (!analysisCols.contains('personal_rating')) {
        batch.execute('ALTER TABLE analyses ADD COLUMN personal_rating INTEGER');
      }
      if (!analysisCols.contains('personal_rating_note')) {
        batch.execute('ALTER TABLE analyses ADD COLUMN personal_rating_note TEXT');
      }
    }

    await batch.commit(noResult: true);

    if (oldVersion < 6) {
      await db.execute('PRAGMA foreign_keys = ON');
    }

    // Reseed knowledge base jika naik ke v3 agar tools & gambar terisi.
    if (oldVersion < 3) {
      await KnowledgeBaseSeeder(db).reseed();
    }

    await db.update(
      'meta',
      <String, Object?>{'value': newVersion.toString()},
      where: 'key = ?',
      whereArgs: <Object?>[kMetaSchemaVersion],
    );
  }

  /// Menutup database (dipakai untuk pengujian).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
