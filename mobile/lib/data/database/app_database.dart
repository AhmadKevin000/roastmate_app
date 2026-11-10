import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String _dbName = 'roastmate.db';
  static const int _dbVersion = 1;

  static AppDatabase? _instance;
  Database? _database;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Memperbolehkan injeksi Database kustom (berguna untuk testing dengan in-memory db / FFI).
  void setDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Aktifkan foreign key cascade
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel Header Analisis
    await db.execute('''
      CREATE TABLE analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_label TEXT,
        batch_name TEXT,
        created_at TEXT NOT NULL,
        image_path TEXT,
        species TEXT,
        roast TEXT,
        visible_beans INTEGER,
        defect_rate REAL,
        quality_score INTEGER,
        quality_profile TEXT,
        grade TEXT,
        summary_text TEXT,
        model_version TEXT
      )
    ''');

    // 2. Tabel Rincian Defect per Analisis
    await db.execute('''
      CREATE TABLE analysis_defects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
        defect_class TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        UNIQUE (analysis_id, defect_class)
      )
    ''');

    // 3. Tabel Deteksi Biji & Bounding Box Overlay
    await db.execute('''
      CREATE TABLE bean_detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
        class_label TEXT NOT NULL,
        rect_left REAL NOT NULL,
        rect_top REAL NOT NULL,
        rect_width REAL NOT NULL,
        rect_height REAL NOT NULL,
        confidence REAL NOT NULL
      )
    ''');

    // 4. Tabel Rekomendasi Seduh Terkalibrasi
    await db.execute('''
      CREATE TABLE recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL UNIQUE REFERENCES analyses(id) ON DELETE CASCADE,
        method_title TEXT NOT NULL,
        reason_text TEXT NOT NULL,
        ratio TEXT NOT NULL,
        ratio_sub TEXT NOT NULL,
        temp_c TEXT NOT NULL,
        temp_c_sub TEXT NOT NULL,
        grind TEXT NOT NULL,
        grind_sub TEXT NOT NULL,
        target_time TEXT NOT NULL,
        target_time_sub TEXT NOT NULL
      )
    ''');

    // 5. Tabel Opsi Metode Alternatif
    await db.execute('''
      CREATE TABLE alternative_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    // Buat index untuk optimasi query riwayat dan join data
    await db.execute('CREATE INDEX idx_analyses_created ON analyses(created_at DESC)');
    await db.execute('CREATE INDEX idx_defects_analysis ON analysis_defects(analysis_id)');
    await db.execute('CREATE INDEX idx_detections_analysis ON bean_detections(analysis_id)');
    await db.execute('CREATE INDEX idx_recommendations_analysis ON recommendations(analysis_id)');
    await db.execute('CREATE INDEX idx_alternatives_analysis ON alternative_methods(analysis_id)');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}

