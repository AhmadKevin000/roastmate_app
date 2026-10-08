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
    // v1 = versi awal; belum ada migrasi. Tambahkan migrasi bertingkat di sini
    // saat kSchemaVersion dinaikkan, lalu perbarui meta.schema_version.
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
