/// Skema database Roastmate (SQLite).
///
/// Sumber kanonik: `docs/DATABASE_SCHEMA.md`.
/// Definisi DDL di sini harus selalu sama dengan dokumen tersebut.
/// Setiap perubahan skema WAJIB menaikkan [kSchemaVersion] + menambah migrasi
/// di `app_database.dart`.
library;

/// Versi skema saat ini.
///
/// v9: sinkronisasi dua arah yang lengkap — tabel outbox `sync_deletes`
/// (tombstone hapus), kolom foto di `analyses` (`image_sync_status`,
/// `image_upload_attempts`, `cloudinary_public_id`) untuk antrean retry.
/// v8: penilaian pribadi user pada `analyses` — `personal_rating` (1–5,
/// NULL = belum dinilai) + `personal_rating_note`.
/// v7: kolom sync (D-29) — `uuid`/`user_id`/`sync_status`/`updated_at` pada
/// `analyses` & `user_brew_recipes`; `uuid`/`sync_status` pada
/// `analysis_defects` & `recommendations`. Kunci lintas device = `uuid`.
/// v6: rebuild `user_brew_recipes` — `method_id` nullable (metode
/// "Lainnya" di luar KB) + kolom `method_name`, `steps`, `video_url`;
/// `brew_recipes` + kolom `video_url`.
/// v5: jaminan kolom `analyses` yang diperkenalkan selama dev untuk DB
/// lama (era dev/bon) — migrasi defensif per kolom, idempoten.
/// v4: tabel `user_brew_recipes` (resep buatan user; di luar KB & reseed).
/// v3: tambah `brew_tools`, `brew_method_tools`, kolom `image_asset` & `subtitle`
/// pada `brew_methods`, serta sinkronisasi taksonomi species (+Liberika)
/// dan defect 4-kelas.
const int kSchemaVersion = 9;

/// Nama file database.
const String kDatabaseName = 'roastmate.db';

/// Path asset seed knowledge base.
const String kKnowledgeSeedAsset = 'assets/knowledge/brewing_knowledge.json';

/// Key pada tabel `meta`.
const String kMetaSchemaVersion = 'schema_version';
const String kMetaKbVersion = 'kb_version';

/// DDL seluruh tabel (mirror `DATABASE_SCHEMA.md` §4–§9).
const List<String> kCreateTableStatements = <String>[
  // §4 brew_methods
  '''
  CREATE TABLE brew_methods (
    method_id    TEXT PRIMARY KEY,
    method_name  TEXT NOT NULL,
    method_type  TEXT NOT NULL
                   CHECK (method_type IN ('pour_over','immersion','hybrid','pressure','espresso')),
    subtitle     TEXT,
    image_asset  TEXT,
    description  TEXT
  )
  ''',
  // §4.1 brew_tools
  '''
  CREATE TABLE brew_tools (
    tool_id      TEXT PRIMARY KEY,
    tool_name    TEXT NOT NULL,
    category     TEXT,
    image_asset  TEXT,
    description  TEXT
  )
  ''',
  // §4.2 brew_method_tools
  '''
  CREATE TABLE brew_method_tools (
    method_id    TEXT NOT NULL REFERENCES brew_methods(method_id) ON DELETE CASCADE,
    tool_id      TEXT NOT NULL REFERENCES brew_tools(tool_id) ON DELETE CASCADE,
    is_required  INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
    notes        TEXT,
    PRIMARY KEY (method_id, tool_id)
  )
  ''',
  // §5 brew_recipes
  '''
  CREATE TABLE brew_recipes (
    recipe_id        TEXT PRIMARY KEY,
    method_id        TEXT NOT NULL REFERENCES brew_methods(method_id),
    species          TEXT NOT NULL CHECK (species IN ('Arabica','Robusta','Liberika','Mixed')),
    quality_profile  TEXT NOT NULL CHECK (quality_profile IN ('High','Medium','Low')),
    roast_context    TEXT NOT NULL CHECK (roast_context IN
                       ('Green','Light','Medium','Dark','Light/Medium','Medium/Dark')),
    dose_g           REAL,
    water_volume_ml  INTEGER,
    grind_size       TEXT CHECK (grind_size IN
                       ('Espresso','Fine','Medium-Fine','Medium','Medium-Coarse','Coarse')),
    temperature_c    INTEGER,
    brewing_time_s   INTEGER,
    source           TEXT NOT NULL,
    is_default       INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0,1)),
    steps            TEXT,
    notes            TEXT,
    video_url        TEXT
  )
  ''',
  // §6 analyses (v7: + kolom sync D-29; v8: + personal rating)
  '''
  CREATE TABLE analyses (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid                  TEXT UNIQUE,
    user_id               TEXT,
    sync_status           TEXT NOT NULL DEFAULT 'local'
                            CHECK (sync_status IN ('local','pending','synced')),
    updated_at            TEXT,
    created_at            TEXT NOT NULL,
    name                  TEXT,
    image_path            TEXT,
    annotated_image_path  TEXT,
    batch_label           TEXT,
    batch_name            TEXT,
    model_version         TEXT,
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
    quality_profile       TEXT CHECK (quality_profile IN ('High','Medium','Low')),
    personal_rating       INTEGER
                            CHECK (personal_rating IS NULL OR personal_rating BETWEEN 1 AND 5),
    personal_rating_note  TEXT,
    image_sync_status     TEXT NOT NULL DEFAULT 'none'
                            CHECK (image_sync_status IN ('none','pending','uploaded','failed')),
    image_upload_attempts INTEGER NOT NULL DEFAULT 0,
    cloudinary_public_id  TEXT
  )
  ''',
  // §7 analysis_defects (v7: + kolom sync D-29)
  '''
  CREATE TABLE analysis_defects (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid          TEXT UNIQUE,
    sync_status   TEXT NOT NULL DEFAULT 'local'
                    CHECK (sync_status IN ('local','pending','synced')),
    analysis_id   INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
    defect_class  TEXT NOT NULL CHECK (defect_class IN
                    ('Normal','Quaker','Broken','Severe')),
    count         INTEGER NOT NULL DEFAULT 0,
    UNIQUE (analysis_id, defect_class)
  )
  ''',
  // §8 recommendations (v7: + kolom sync D-29)
  '''
  CREATE TABLE recommendations (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid                  TEXT UNIQUE,
    sync_status           TEXT NOT NULL DEFAULT 'local'
                            CHECK (sync_status IN ('local','pending','synced')),
    analysis_id           INTEGER NOT NULL UNIQUE
                            REFERENCES analyses(id) ON DELETE CASCADE,
    primary_method_id     TEXT NOT NULL REFERENCES brew_methods(method_id),
    primary_recipe_id     TEXT NOT NULL REFERENCES brew_recipes(recipe_id),
    alternative_method_id TEXT REFERENCES brew_methods(method_id),
    reason                TEXT
  )
  ''',
  // §9.5 user_brew_recipes (resep buatan user — di luar KB & reseed)
  //
  // `method_id` nullable: null = metode "Lainnya" (di luar KB);
  // `method_name` menyimpan nama display untuk semua resep (v6);
  // v7: + kolom sync D-29.
  '''
  CREATE TABLE user_brew_recipes (
    recipe_id        TEXT PRIMARY KEY,
    uuid             TEXT UNIQUE,
    user_id          TEXT,
    sync_status      TEXT NOT NULL DEFAULT 'local'
                       CHECK (sync_status IN ('local','pending','synced')),
    updated_at       TEXT,
    name             TEXT NOT NULL,
    method_id        TEXT REFERENCES brew_methods(method_id) ON DELETE SET NULL,
    method_name      TEXT NOT NULL,
    species          TEXT NOT NULL CHECK (species IN ('Arabica','Robusta','Liberika','Mixed')),
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
  ''',
  // §9 meta
  '''
  CREATE TABLE meta (
    key    TEXT PRIMARY KEY,
    value  TEXT NOT NULL
  )
  ''',
  // §9.6 sync_deletes (v9) — outbox tombstone: baris yang sudah dihapus lokal
  // tapi belum dihapus di cloud. Lihat DATABASE_SCHEMA.md §16.
  '''
  CREATE TABLE sync_deletes (
    uuid        TEXT PRIMARY KEY,
    table_name  TEXT NOT NULL CHECK (table_name IN ('analyses','user_brew_recipes')),
    deleted_at  TEXT NOT NULL,
    synced      INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
  )
  ''',
];

/// DDL seluruh index (mirror `DATABASE_SCHEMA.md` §10).
const List<String> kCreateIndexStatements = <String>[
  'CREATE INDEX idx_recipes_method ON brew_recipes(method_id)',
  'CREATE INDEX idx_recipes_lookup ON brew_recipes(species, roast_context, is_default)',
  'CREATE INDEX idx_method_tools_tool ON brew_method_tools(tool_id)',
  'CREATE INDEX idx_analyses_created ON analyses(created_at)',
  'CREATE INDEX idx_defects_analysis ON analysis_defects(analysis_id)',
  'CREATE INDEX idx_recommendations_analysis ON recommendations(analysis_id)',
  'CREATE INDEX idx_analyses_sync ON analyses(sync_status)',
  'CREATE INDEX idx_analyses_image_sync ON analyses(image_sync_status)',
];
