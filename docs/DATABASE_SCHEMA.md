# ROASTMATE — DATABASE SCHEMA

Versi: 1.7 (skema DB `schema_version` = 7 — kolom sync `uuid`/`user_id`/`sync_status`/`updated_at` pada tabel sync; + skema cloud Supabase §16 — D-29)
Status: Spesifikasi kanonik. Definisi tabel **hanya di dokumen ini**; dokumen lain merujuk ke sini.

---

## 1. Prinsip & Cakupan

- Satu database **SQLite** lokal, seluruhnya on-device.
- Tiga kelompok: **Knowledge Base** (statis, read-only saat runtime),
  **Riwayat** (dinamis, ditulis saat runtime), dan **User Data**
  (resep buatan user, dinamis — Plan 4).
- Parameter seduh hanya dimiliki `brew_recipes` (D-10).
- `grade` **tidak disimpan**; diturunkan dari `quality_profile` (D-02).
- Tabel didefinisikan dalam **DDL** di dokumen ini; migrasi dikelola via `schema_version`.

---

## 2. Daftar Tabel

| Tabel               | Kelompok       | Keterangan                                     |
| ------------------- | -------------- | ---------------------------------------------- |
| `brew_methods`      | Knowledge Base | Metadata metode                                |
| `brew_tools`        | Knowledge Base | Master alat seduh                              |
| `brew_method_tools` | Knowledge Base | Relasi metode ↔ alat seduh                     |
| `brew_recipes`      | Knowledge Base | Parameter seduh + provenance                   |
| `analyses`          | Riwayat (sync) | Satu sesi analisis batch                       |
| `analysis_defects`  | Riwayat (sync) | Rincian defect per analisis                    |
| `recommendations`   | Riwayat (sync) | Rekomendasi per analisis                       |
| `user_brew_recipes` | User Data (sync) | Resep buatan user (di luar KB)               |
| `meta`              | Internal       | `schema_version`, `kb_version`                 |

> Tabel bertanda **sync** membawa kolom tambahan untuk sinkronisasi antar device
> (D-29): `uuid` (kunci identitas lintas device), `user_id` (pemilik, dari auth),
> `sync_status` (`local` · `pending` · `synced`), dan `updated_at`. Lihat §16.

---

## 3. Diagram Relasi

```
brew_tools 1 ──── N brew_method_tools N ──── 1 brew_methods 1 ──── N brew_recipes
                                                                         ↑
analyses 1 ── N analysis_defects                                         │
    │                                                                    │
    └── 1 ── 1 recommendations ──→ brew_methods (primary/alternative)    │
                              └──→ brew_recipes (primary_recipe_id) ─────┘

user_brew_recipes N ──── 1 brew_methods (method_id; kelompok User Data)
```

---

## 4. Tabel `brew_methods`

Deskriptif. Tidak menyimpan parameter seduh.

```sql
CREATE TABLE brew_methods (
  method_id    TEXT PRIMARY KEY,
  method_name  TEXT NOT NULL,
  method_type  TEXT NOT NULL
                 CHECK (method_type IN ('pour_over','immersion','hybrid','pressure','espresso')),
  subtitle     TEXT,
  image_asset  TEXT,
  description  TEXT
);
```

Contoh: `M001 V60 pour_over` · `M002 French Press immersion` · `M003 AeroPress hybrid` · `M004 Moka Pot pressure` · `M005 Kopi Tubruk immersion`.

---

## 4.1 Tabel `brew_tools`

Master data alat seduh (reusable antar metode).

```sql
CREATE TABLE brew_tools (
  tool_id      TEXT PRIMARY KEY,
  tool_name    TEXT NOT NULL,
  category     TEXT,
  image_asset  TEXT,
  description  TEXT
);
```

Contoh: `T001 Dripper V60` · `T002 Paper Filter` · `T003 Gooseneck Kettle` · `T004 Digital Scale`.

---

## 4.2 Tabel `brew_method_tools`

Relasi banyak-ke-banyak (N:M) antara metode seduh dan alat yang dibutuhkan.

```sql
CREATE TABLE brew_method_tools (
  method_id    TEXT NOT NULL REFERENCES brew_methods(method_id) ON DELETE CASCADE,
  tool_id      TEXT NOT NULL REFERENCES brew_tools(tool_id) ON DELETE CASCADE,
  is_required  INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
  notes        TEXT,
  PRIMARY KEY (method_id, tool_id)
);
```

---

## 5. Tabel `brew_recipes`

Otoritatif. Pemilik seluruh parameter seduh.

```sql
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
);
```

| Kolom             | Tipe    | Arti                                                                                  |
| ----------------- | ------- | ------------------------------------------------------------------------------------- |
| `recipe_id`       | TEXT    | PK, mis. `R001`                                                                       |
| `method_id`       | TEXT    | FK → `brew_methods`                                                                   |
| `species`         | TEXT    | `Arabica` · `Robusta` · `Liberika` · `Mixed`                                          |
| `quality_profile` | TEXT    | `High` · `Medium` · `Low`                                                             |
| `roast_context`   | TEXT    | Lihat bagian 11                                                                       |
| `dose_g`          | REAL    | Berat kopi bubuk (gram)                                                               |
| `water_volume_ml` | INTEGER | Volume air (ml)                                                                       |
| `grind_size`      | TEXT    | Kategori: `Espresso` · `Fine` · `Medium-Fine` · `Medium` · `Medium-Coarse` · `Coarse` |
| `temperature_c`   | INTEGER | Suhu air (°C)                                                                         |
| `brewing_time_s`  | INTEGER | Target waktu seduh (detik)                                                            |
| `source`          | TEXT    | Kode provenance (BR001–BR004)                                                         |
| `is_default`      | INTEGER | `1` = resep umum katalog metode                                                       |
| `steps`           | TEXT    | JSON langkah; tiap item punya `phase`: `prep` \| `brew`                               |
| `notes`           | TEXT    | Tips kalibrasi rasa & catatan resep                                                   |
| `video_url`       | TEXT    | Link video YouTube panduan seduh (opsional; v6). Ditampilkan di Detail Resep         |

Rasio **tidak disimpan**; dihitung `water_volume_ml / dose_g`.

---

## 6. Tabel `analyses`

Satu sesi analisis batch.

```sql
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
  personal_rating_note  TEXT
);
```

Catatan:

- `grade` **tidak ada** di sini — diturunkan dari `quality_profile` saat tampil.
- `status` (`uncertain`) **tidak disimpan** — diturunkan dari `roast_confidence` vs ambang (lihat bagian 15).
- `annotated_image_path` = gambar dengan overlay bounding box, **boleh kosong**. Riwayat menampilkan foto asli (`image_path`) + rekap `analysis_defects`; overlay hanya pada layar hasil analisis langsung (D-20).
- `batch_label` = label pendek batch (mis. `Batch #042`); `batch_name` = nama batch (mis. `Mandheling Honey Anaerob`).
- `model_version` = versi model yang menghasilkan analisis (provenance, mis. `Model CV v2.4`).
- `image_path` = path foto **di perangkat** atau Cloudinary `secure_url` — di-UPDATE ke URL setelah upload sukses (best-effort, offline-first: gagal/offline tetap path lokal). Thumbnail di list (Beranda/Riwayat) dirender via `AnalysisImage`; URL Cloudinary di-resize dengan transformasi `c_fill` (lihat `ARCHITECTURE_MOBILE.md` §12).
- Deteksi per-biji (bounding box, confidence) **tidak disimpan** (D-20).
- `species` = **satu jenis biji kopi dominan** (`Arabica`/`Robusta`/`Liberika`/`Mixed`). Tidak ada kolom sebaran maupun confidence species (D-15).
- `roast_distribution` = JSON agregat batch (mis. `{"Light": 3, "Medium": 19}`), dipakai Beranda & ML §7.
- Kolom `name`, `batch_label`, `batch_name`, `model_version`, `image_path`, `annotated_image_path` dijamin eksis pada DB lama oleh migrasi v5 (defensif per kolom — lihat §12).
- Kolom sync (v7, D-29): `uuid` = UUID v4 kunci identitas lintas device (di-backfill saat pertama sync untuk baris lama); `user_id` = ID user auth (Supabase `auth.users.id`), terisi saat login; `sync_status` = `local` (belum login/tak ikut sync) · `pending` (menunggu dikirim) · `synced` (sudah di cloud); `updated_at` = ISO-8601 untuk audit.
- Kolom penilaian pribadi (v8, D-31): `personal_rating` = bintang 1–5 yang diisi user di Detail Inspeksi, `NULL` = belum dinilai; `personal_rating_note` = catatan opsional (kosong disimpan `NULL`). Ini penilaian subjektif user, **bukan** bagian quality score dan tidak dipakai rule engine. Kartu Beranda & Riwayat menampilkannya sebagai bintang.

---

## 7. Tabel `analysis_defects`

Rincian defect per analisis.

```sql
CREATE TABLE analysis_defects (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid          TEXT UNIQUE,
  sync_status   TEXT NOT NULL DEFAULT 'local'
                  CHECK (sync_status IN ('local','pending','synced')),
  analysis_id   INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
  defect_class  TEXT NOT NULL CHECK (defect_class IN ('Normal','Quaker','Broken','Severe')),
  count         INTEGER NOT NULL DEFAULT 0,
  UNIQUE (analysis_id, defect_class)
);
```

> Defect terdiri dari **4 kelas** (`Normal` / `Quaker` / `Broken` / `Severe`) — sesuai taksonomi final hasil training (ML_PBL). Sub-jenis parah (`under`, `burnt`, `insectOrMold`) digabung ke `Severe` saat training karena sampel terlalu sedikit; pembedanya direkonstruksi sebagai narasi turunan (`underdeveloped` / `overroasted` / `contamination`) dari kombinasi `Severe` + `roast` (lihat bagian 15). Benda asing / bukan biji (Foreign Matter) ditangani oleh detector, bukan classifier.

---

## 8. Tabel `recommendations`

Rekomendasi per analisis. Parameter seduh **tidak diduplikasi** — cukup `primary_recipe_id`.

> `reason` diisi dari **template naratif per konteks species × roast** (`assets/knowledge/reason_templates.json`, 12 key `Species|Roast`) sampai engine ML/LLM menghasilkan rekomendasi adaptif.

```sql
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
);
```

**Cara baca (Detail Inspeksi):** join `brew_methods` (nama + subtitle metode) + `brew_recipes` — parameter primary dari `primary_recipe_id`; alternatif dari resep **default species analisis** untuk `alternative_method_id`. Parameter seduh tetap tidak diduplikasi (lihat `ARCHITECTURE_MOBILE.md` §12).

---

## 9. Tabel `meta`

```sql
CREATE TABLE meta (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);
```

Isi awal: `schema_version`, `kb_version`.

---

## 9.5 Tabel `user_brew_recipes` (v4, bentuk final v6)

Resep seduh buatan user (Plan 4). Kelompok **User Data** — tabel terpisah
dari KB: **tidak ikut reseed `kb_version`** dan **tidak dipakai
recommendation engine** (lookup rekomendasi hanya `brew_recipes`).

```sql
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
);
```

Catatan:

- `recipe_id` = prefix `U` + epoch-micros, di-generate repository
  (mis. `U1750000000000000`).
- `method_id` **nullable** (v6): `NULL` = metode "Lainnya" yang tidak ada
  di KB. `method_name` menyimpan nama display untuk semua resep — dari
  dropdown KB atau input bebas form — sehingga UI tetap utuh meski
  `method_id` hilang (mis. akibat reseed KB; lihat `ON DELETE SET NULL`).
- `steps` (v6): JSON array, shape sama dengan `brew_recipes.steps`
  (`stepNo`, `phase`, `title`, `description?`, `targetTime?`).
- `video_url` (v6): link video YouTube (opsional).
- Tanpa kolom `source`/`is_default` — saat parse ke entity di-mapping
  tetap: `source='USER'`, `isDefault=false`.
- `created_at` hanya untuk ordering tampil (terbaru dulu); volume kecil →
  sort in-memory, tanpa index baru.
- Rebuild v5→v6 memakai pola resmi SQLite (foreign_keys OFF → create new
  → INSERT SELECT → drop → rename → ON); `method_name` data lama
  di-resolve via join `brew_methods`, fallback string `method_id`.

---

## 10. Index

```sql
CREATE INDEX idx_recipes_method        ON brew_recipes(method_id);
CREATE INDEX idx_recipes_lookup        ON brew_recipes(species, roast_context, is_default);
CREATE INDEX idx_method_tools_tool     ON brew_method_tools(tool_id);
CREATE INDEX idx_analyses_created      ON analyses(created_at);
CREATE INDEX idx_defects_analysis      ON analysis_defects(analysis_id);
CREATE INDEX idx_recommendations_analysis ON recommendations(analysis_id);
```

| Index                          | Tujuan                                         |
| ------------------------------ | ---------------------------------------------- |
| `idx_recipes_method`           | Join method → resep                            |
| `idx_recipes_lookup`           | Filter katalog/rekomendasi per species & roast |
| `idx_method_tools_tool`        | Ambil alat untuk suatu metode (join terbalik)  |
| `idx_analyses_created`         | Urut riwayat berdasarkan waktu                 |
| `idx_defects_analysis`         | Ambil defect per analisis                      |
| `idx_recommendations_analysis` | Ambil rekomendasi per analisis                 |

---

## 11. Enum & Nilai Sah

| Domain            | Nilai                                                                       |
| ----------------- | --------------------------------------------------------------------------- |
| `species`         | `Arabica` · `Robusta` · `Liberika` · `Mixed`                                |
| `status`          | `OK` · `Uncertain`                                                          |
| `roast`           | `Green` · `Light` · `Medium` · `Dark`                                       |
| `quality_profile` | `High` · `Medium` · `Low`                                                   |
| `roast_context`   | `Green` · `Light` · `Medium` · `Dark` · `Light/Medium` · `Medium/Dark`      |
| `grind_size`      | `Espresso` · `Fine` · `Medium-Fine` · `Medium` · `Medium-Coarse` · `Coarse` |
| `method_type`     | `pour_over` · `immersion` · `hybrid` · `pressure` · `espresso`              |
| `defect_class`    | `Normal` · `Quaker` · `Broken` · `Severe`                                   |

Enum yang **disimpan** memakai **Title Case** (kecuali `method_type` snake_case). Nilai di JSON seed harus mengikuti ini. `status` adalah nilai **turunan/tampilan** (tidak disimpan, tidak masuk seed). Kolom enum ditegakkan dengan **`CHECK` constraint** pada DDL (bukan hanya konvensi).

---

## 12. Migrasi & Versi

- Versi skema disimpan di `meta.schema_version`.
- `sqflite` `onCreate` membuat seluruh tabel untuk versi terkini.
- `onUpgrade` menerapkan migrasi bertingkat sesuai `schema_version`.
- Perubahan skema **wajib** menambah migrasi + menaikkan `schema_version`.
- Versi knowledge base disimpan terpisah di `meta.kb_version` (dapat diperbarui tanpa mengubah skema).

### Migrasi tercatat

| Dari | Ke  | Perubahan         | Status               |
| ---- | --- | ----------------- | -------------------- |
| v1   | v2  | Kolom `analyses`: `name`, `batch_label`, `batch_name`, `model_version` (D-19/D-20) | Tercatat |
| v2   | v3  | Tabel `brew_tools`, `brew_method_tools`; kolom `brew_methods.subtitle`/`image_asset`; reseed KB (tools & gambar) | Tercatat |
| v3   | v4  | Tabel `user_brew_recipes` (resep user, kelompok User Data) | Tercatat |
| v4   | v5  | Jaminan kolom legacy `analyses` (`name`, `batch_label`, `batch_name`, `model_version`, `image_path`, `annotated_image_path`) — cek per kolom via `PRAGMA table_info`, idempoten | Tercatat |
| v5   | v6  | Rebuild `user_brew_recipes` (pola resmi SQLite; foreign_keys OFF selama rebuild): `method_id` nullable + `ON DELETE SET NULL`, kolom baru `method_name`, `steps`, `video_url`; data lama dipindah, `method_name` di-resolve dari join `brew_methods`. `brew_recipes` + kolom `video_url` (ALTER, guarded idempoten) | Tercatat |
| v6   | v7  | Kolom sync (D-29, ALTER guarded idempoten per kolom): `analyses` + `user_brew_recipes` → `uuid`, `user_id`, `sync_status DEFAULT 'local'`, `updated_at`; `analysis_defects` + `recommendations` → `uuid`, `sync_status DEFAULT 'local'`. Index `idx_analyses_sync` (`sync_status`). Baris lama tetap `sync_status='local'`; backfill `uuid` dilakukan saat pertama sync, bukan di migrasi | Tercatat |
| v7   | v8  | Kolom penilaian pribadi (D-31, ALTER guarded idempoten per kolom): `analyses` → `personal_rating` (INTEGER, NULL = belum dinilai), `personal_rating_note` (TEXT). Rentang 1–5 divalidasi repository (CHECK tidak bisa ditambahkan lewat ALTER) | Tercatat |

`kSchemaVersion` terkini = **8**.

> Skema versi terkini sudah memakai taksonomi final hasil training (species 3 kelas + `Liberika`, defect 4 kelas). Tidak ada migrasi data yang diperlukan karena belum ada rilis dengan taksonomi lama. Saat taksonomi berubah di masa depan, `kSchemaVersion` dinaikkan + migrasi ditambahkan.

---

## 13. Format Seed

Sumber seed: `assets/knowledge/brewing_knowledge.json`.

```json
{
  "kb_version": "1.2",
  "tools": [
    {
      "tool_id": "T001",
      "tool_name": "Dripper V60",
      "category": "dripper",
      "image_asset": "assets/images/tools/dripper_v60.png",
      "description": "..."
    }
  ],
  "methods": [
    {
      "method_id": "M001",
      "method_name": "V60",
      "method_type": "pour_over",
      "subtitle": "Clean & Bright",
      "image_asset": "assets/images/methods/v60.png",
      "description": "...",
      "tools": [
        { "tool_id": "T001", "is_required": 1, "notes": "Ukuran 01 atau 02" }
      ]
    }
  ],
  "recipes": [
    {
      "recipe_id": "R001",
      "method_id": "M001",
      "species": "Arabica",
      "quality_profile": "High",
      "roast_context": "Light/Medium",
      "dose_g": 15,
      "water_volume_ml": 225,
      "grind_size": "Medium-Fine",
      "temperature_c": 92,
      "brewing_time_s": 165,
      "source": "BR001",
      "is_default": 1,
      "notes": "Sesuaikan grind bila seduhan terlalu pahit.",
      "video_url": "https://www.youtube.com/watch?v=...",
      "steps": [
        {
          "stepNo": 1,
          "phase": "prep",
          "title": "Rinsing filter",
          "description": "..."
        },
        {
          "stepNo": 2,
          "phase": "brew",
          "title": "Bloom",
          "description": "..."
        }
      ]
    }
  ]
}
```

Alur seed: `JSON → KnowledgeBaseSeeder → SQLite`. Seeding hanya berjalan bila `brew_methods` masih kosong (idempoten); naik skema ke v3 menjalankan reseed agar `brew_tools`/`brew_method_tools` terisi. Setelah itu SQLite menjadi satu-satunya sumber query runtime. `video_url` pada resep seed bersifat opsional (v6): saat link diisi di JSON, naikkan `kb_version` untuk memicu reseed.

> **Coverage `kb_version` 1.2 (14 resep):** R001–R003 (seed awal) + R004–R014 — **1 resep default per kombinasi species × roast** untuk 4 species (`Arabica`/`Robusta`/`Liberika`/`Mixed`) × 3 roast (`Light`/`Medium`/`Dark`). Dengan cakupan ini FK `recommendations.primary_recipe_id` selalu bisa dipenuhi untuk hasil analisis ber-roast matang (AC-04: `Green` tidak menerima rekomendasi). Bila `kb_version` asset naik, `KnowledgeBaseSeeder.seedIfEmpty()` melakukan **reseed otomatis** saat database dibuka (DB dev lama terselamatkan tanpa hapus data manual).

---

## 14. Aturan Integritas

1. `brew_recipes.method_id` harus ada di `brew_methods`.
2. `recommendations.primary_recipe_id` harus ada di `brew_recipes`; resep harus milik `primary_method_id`.
3. Satu `analysis` maksimal punya satu baris `recommendations`.
4. `analysis_defects` unik per (`analysis_id`, `defect_class`).
5. `analyses` dan turunannya dihapus berantai (`ON DELETE CASCADE`).
6. Nilai enum harus sesuai bagian 11; ditegakkan `CHECK` pada `brew_methods` (`method_type`), `brew_recipes` (`species`, `quality_profile`, `roast_context`, `grind_size`), `analyses` (`species`, `roast`, `quality_profile`), `analysis_defects` (`defect_class`), dan `user_brew_recipes` (`species`, `quality_profile`, `roast_context`, `grind_size`).
7. `source` wajib terisi (traceability BR001–BR004).
8. `user_brew_recipes.method_id` boleh `NULL` (metode "Lainnya", v6); `method_name` wajib terisi. Bila baris `brew_methods` dihapus (reseed KB), referensi ikut `ON DELETE SET NULL` — baris resep user tidak pernah ikut terhapus.

---

## 15. Nilai Turunan & Nilai Dihitung

| Nilai                   | Asal                                                                                | Disimpan?                      |
| ----------------------- | ----------------------------------------------------------------------------------- | ------------------------------ |
| `grade`                 | `quality_profile` (pemetaan D-02)                                                   | Tidak                          |
| Rasio                   | `water_volume_ml / dose_g`                                                          | Tidak                          |
| `status` (`uncertain`)  | `roast_confidence` vs ambang                                                        | Tidak                          |
| `defect_interpretation` | `counts.Severe` + `analyses.roast` (`underdeveloped`/`overroasted`/`contamination`) | Tidak — diturunkan saat render |
| `defect_rate`           | hitung saat analisis (snapshot)                                                     | Ya                             |
| `roast_distribution`    | agregasi batch saat analisis                                                        | Ya (JSON)                      |

---

## 16. Skema Cloud — Supabase (D-29)

Satu project Supabase (Postgres). Struktur tabel cloud **cermin** dari tabel sync
lokal, dengan perbedaan kunci: **PK cloud = `uuid`** (TEXT) — bukan AUTOINCREMENT
lokal. Baris di-upsert berdasarkan `uuid` (union by uuid, append-only).

```sql
create table analyses (
  uuid                 text primary key,
  user_id              uuid not null references auth.users(id) on delete cascade,
  created_at           text not null,
  name                 text,
  image_path           text,            -- URL Cloudinary atau path lokal (lihat D-29)
  annotated_image_path text,
  batch_label          text,
  batch_name           text,
  model_version        text,
  species              text check (species in ('Arabica','Robusta','Liberika','Mixed')),
  roast                text check (roast in ('Green','Light','Medium','Dark')),
  roast_confidence     real,
  roast_distribution   text,
  visible_beans        integer,
  defect_rate          real,
  shape_uniformity     real,
  size_uniformity      real,
  roast_uniformity     real,
  quality_score        integer,
  quality_profile      text check (quality_profile in ('High','Medium','Low'))
);

create table analysis_defects (
  uuid          text primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  analysis_uuid text not null references analyses(uuid) on delete cascade,
  defect_class  text not null check (defect_class in ('Normal','Quaker','Broken','Severe')),
  count         integer not null default 0,
  unique (analysis_uuid, defect_class)
);

create table recommendations (
  uuid                  text primary key,
  user_id               uuid not null references auth.users(id) on delete cascade,
  analysis_uuid         text not null unique references analyses(uuid) on delete cascade,
  primary_method_id     text not null,
  primary_recipe_id     text not null,
  alternative_method_id text,
  reason                text
);

create table user_brew_recipes (
  uuid             text primary key,
  user_id          uuid not null references auth.users(id) on delete cascade,
  recipe_id        text not null,       -- ID lokal asal (tetap disimpan untuk provenance)
  n             text not null,
  method_id        text,
  method_name      text not null,
  species          text check (species in ('Arabica','Robusta','Liberika','Mixed')),
  quality_profile  text check (quality_profile in ('High','Medium','Low')),
  roast_context    text check (roast_context in
                     ('Green','Light','Medium','Dark','Light/Medium','Medium/Dark')),
  dose_g           real,
  water_volume_ml  integer,
  grind_size       text,
  temperature_c    integer,
  brewing_time_s   integer,
  steps            text,
  video_url        text,
  notes            text,
  created_at       text not null
);

create index idx_cloud_analyses_user on analyses(user_id, created_at);
create index idx_cloud_defects_analysis on analysis_defects(analysis_uuid);
```

### Row Level Security (wajib)

```sql
alter table analyses            enable row level security;
alter table analysis_defects    enable row level security;
alter table recommendations     enable row level security;
alter table user_brew_recipes   enable row level security;

-- pola yang sama untuk keempat tabel (contoh: analyses)
create policy "own rows all" on analyses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

### Aturan cloud

1. **RLS wajib aktif** di semua tabel sync; anon key tanpa login tidak melihat
   apa pun.
2. Referensi KB (`primary_method_id`, `primary_recipe_id`, dst.) disimpan sebagai
   **ID mentah tanpa FK** — device lain meresolusi dari knowledge base lokalnya
   (versi KB dijamin ≥ seed 1.2 yang mencakup semua kombinasi species × roast).
3. Push = upsert by `uuid`; pull = ambil baris `user_id` milik sendiri yang
   `uuid`-nya belum ada di SQLite lokal. Data riwayat immutable → tidak ada
   konflik update; `updated_at` hanya untuk audit.
4. Hapus di cloud = `DELETE by uuid` best-effort saat user menghapus riwayat;
   tanpa tombstone (delete di device lain tidak di-pull — keterbatasan D-29).
5. Baris dengan `image_path` lokal tidak diubah; device lain menampilkan
   placeholder bila path bukan URL.
