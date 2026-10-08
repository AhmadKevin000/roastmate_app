/// Skema database Roastmate (SQLite).
///
/// Sumber kanonik: `docs/DATABASE_SCHEMA.md`.
/// Definisi DDL di sini harus selalu sama dengan dokumen tersebut.
/// Setiap perubahan skema WAJIB menaikkan [kSchemaVersion] + menambah migrasi
/// di `app_database.dart`.
library;

/// Versi skema saat ini.
const int kSchemaVersion = 1;

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
    description  TEXT
  )
  ''',
  // §5 brew_recipes
  '''
  CREATE TABLE brew_recipes (
    recipe_id        TEXT PRIMARY KEY,
    method_id        TEXT NOT NULL REFERENCES brew_methods(method_id),
    species          TEXT NOT NULL CHECK (species IN ('Arabica','Robusta','Mixed')),
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
    notes            TEXT
  )
  ''',
  // §6 analyses
  '''
  CREATE TABLE analyses (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at            TEXT NOT NULL,
    image_path            TEXT,
    annotated_image_path  TEXT,
    species               TEXT CHECK (species IN ('Arabica','Robusta','Mixed')),
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
  ''',
  // §7 analysis_defects
  '''
  CREATE TABLE analysis_defects (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id   INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
    defect_class  TEXT NOT NULL CHECK (defect_class IN
                    ('Healthy','Broken','Insect Damage','Quaker','Scorched','Foreign Matter')),
    count         INTEGER NOT NULL DEFAULT 0,
    UNIQUE (analysis_id, defect_class)
  )
  ''',
  // §8 recommendations
  '''
  CREATE TABLE recommendations (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id           INTEGER NOT NULL UNIQUE
                            REFERENCES analyses(id) ON DELETE CASCADE,
    primary_method_id     TEXT NOT NULL REFERENCES brew_methods(method_id),
    primary_recipe_id     TEXT NOT NULL REFERENCES brew_recipes(recipe_id),
    alternative_method_id TEXT REFERENCES brew_methods(method_id),
    reason                TEXT
  )
  ''',
  // §9 meta
  '''
  CREATE TABLE meta (
    key    TEXT PRIMARY KEY,
    value  TEXT NOT NULL
  )
  ''',
];

/// DDL seluruh index (mirror `DATABASE_SCHEMA.md` §10).
const List<String> kCreateIndexStatements = <String>[
  'CREATE INDEX idx_recipes_method ON brew_recipes(method_id)',
  'CREATE INDEX idx_recipes_lookup ON brew_recipes(species, roast_context, is_default)',
  'CREATE INDEX idx_analyses_created ON analyses(created_at)',
  'CREATE INDEX idx_defects_analysis ON analysis_defects(analysis_id)',
  'CREATE INDEX idx_recommendations_analysis ON recommendations(analysis_id)',
];
