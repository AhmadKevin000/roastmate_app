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
    return openDatabase(
      path,
      version: kSchemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

    await KnowledgeBaseSeeder(db).seedIfEmpty();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi bertingkat: jalankan langkah dari oldVersion sampai newVersion.
    final batch = db.batch();

    // v1 → v2: kolom identitas batch & provenance model (D-19).
    if (oldVersion < 2) {
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
      batch.execute('CREATE INDEX IF NOT EXISTS idx_method_tools_tool ON brew_method_tools(tool_id)');
    }

    await batch.commit(noResult: true);

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
