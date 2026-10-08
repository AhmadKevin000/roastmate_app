# ROASTMATE — DATABASE SCHEMA

Versi: 1.0
Status: Spesifikasi kanonik. Definisi tabel **hanya di dokumen ini**; dokumen lain merujuk ke sini.

---

## 1. Prinsip & Cakupan

- Satu database **SQLite** lokal, seluruhnya on-device.
- Dua kelompok: **Knowledge Base** (statis, read-only saat runtime) dan **Riwayat** (dinamis, ditulis saat runtime).
- Parameter seduh hanya dimiliki `brew_recipes` (D-10).
- `grade` **tidak disimpan**; diturunkan dari `quality_profile` (D-02).
- Tabel didefinisikan dalam **DDL** di dokumen ini; migrasi dikelola via `schema_version`.

---

## 2. Daftar Tabel

| Tabel | Kelompok | Keterangan |
|---|---|---|
| `brew_methods` | Knowledge Base | Metadata metode |
| `brew_recipes` | Knowledge Base | Parameter seduh + provenance |
| `analyses` | Riwayat | Satu sesi analisis batch |
| `analysis_defects` | Riwayat | Rincian defect per analisis |
| `recommendations` | Riwayat | Rekomendasi per analisis |
| `meta` | Internal | `schema_version`, `kb_version` |

---

## 3. Diagram Relasi

```
brew_methods 1 ──── N brew_recipes
                          ↑
analyses 1 ── N analysis_defects
    │
    └── 1 ── 1 recommendations ──→ brew_methods (primary/alternative)
                              └──→ brew_recipes (primary_recipe_id)
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
  description  TEXT
);
```

Contoh: `M001 V60 pour_over` · `M002 French Press immersion` · `M003 AeroPress hybrid` · `M004 Moka Pot pressure` · `M005 Kopi Tubruk immersion`.

---

## 5. Tabel `brew_recipes`

Otoritatif. Pemilik seluruh parameter seduh.

```sql
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
);
```

| Kolom | Tipe | Arti |
|---|---|---|
| `recipe_id` | TEXT | PK, mis. `R001` |
| `method_id` | TEXT | FK → `brew_methods` |
| `species` | TEXT | `Arabica` · `Robusta` · `Mixed` |
| `quality_profile` | TEXT | `High` · `Medium` · `Low` |
| `roast_context` | TEXT | Lihat bagian 11 |
| `dose_g` | REAL | Berat kopi bubuk (gram) |
| `water_volume_ml` | INTEGER | Volume air (ml) |
| `grind_size` | TEXT | Kategori: `Espresso` · `Fine` · `Medium-Fine` · `Medium` · `Medium-Coarse` · `Coarse` |
| `temperature_c` | INTEGER | Suhu air (°C) |
| `brewing_time_s` | INTEGER | Target waktu seduh (detik) |
| `source` | TEXT | Kode provenance (BR001–BR004) |
| `is_default` | INTEGER | `1` = resep umum katalog metode |
| `steps` | TEXT | JSON langkah; tiap item punya `phase`: `prep` \| `brew` |
| `notes` | TEXT | Tips kalibrasi rasa & catatan resep |

Rasio **tidak disimpan**; dihitung `water_volume_ml / dose_g`.

---

## 6. Tabel `analyses`

Satu sesi analisis batch.

```sql
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
);
```

Catatan:
- `grade` **tidak ada** di sini — diturunkan dari `quality_profile` saat tampil.
- `status` (`uncertain`) **tidak disimpan** — diturunkan dari `roast_confidence` vs ambang (lihat bagian 15).
- `annotated_image_path` = gambar dengan overlay bounding box, dipakai sebagai bukti visual (PRD FR-04).
- `species` = **satu jenis biji kopi dominan** (`Arabica`/`Robusta`/`Mixed`). Tidak ada kolom sebaran maupun confidence species (D-15).
- `roast_distribution` = JSON agregat batch (mis. `{"Light": 3, "Medium": 19}`), dipakai Beranda & ML §7.

---

## 7. Tabel `analysis_defects`

Rincian defect per analisis.

```sql
CREATE TABLE analysis_defects (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  analysis_id   INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
  defect_class  TEXT NOT NULL CHECK (defect_class IN
                  ('Healthy','Broken','Insect Damage','Quaker','Scorched','Foreign Matter')),
  count         INTEGER NOT NULL DEFAULT 0,
  UNIQUE (analysis_id, defect_class)
);
```

---

## 8. Tabel `recommendations`

Rekomendasi per analisis. Parameter seduh **tidak diduplikasi** — cukup `primary_recipe_id`.

```sql
CREATE TABLE recommendations (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  analysis_id           INTEGER NOT NULL UNIQUE
                          REFERENCES analyses(id) ON DELETE CASCADE,
  primary_method_id     TEXT NOT NULL REFERENCES brew_methods(method_id),
  primary_recipe_id     TEXT NOT NULL REFERENCES brew_recipes(recipe_id),
  alternative_method_id TEXT REFERENCES brew_methods(method_id),
  reason                TEXT
);
```

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

## 10. Index

```sql
CREATE INDEX idx_recipes_method        ON brew_recipes(method_id);
CREATE INDEX idx_recipes_lookup        ON brew_recipes(species, roast_context, is_default);
CREATE INDEX idx_analyses_created      ON analyses(created_at);
CREATE INDEX idx_defects_analysis      ON analysis_defects(analysis_id);
CREATE INDEX idx_recommendations_analysis ON recommendations(analysis_id);
```

| Index | Tujuan |
|---|---|
| `idx_recipes_method` | Join method → resep |
| `idx_recipes_lookup` | Filter katalog/rekomendasi per species & roast |
| `idx_analyses_created` | Urut riwayat berdasarkan waktu |
| `idx_defects_analysis` | Ambil defect per analisis |
| `idx_recommendations_analysis` | Ambil rekomendasi per analisis |

---

## 11. Enum & Nilai Sah

| Domain | Nilai |
|---|---|
| `species` | `Arabica` · `Robusta` · `Mixed` |
| `status` | `OK` · `Uncertain` |
| `roast` | `Green` · `Light` · `Medium` · `Dark` |
| `quality_profile` | `High` · `Medium` · `Low` |
| `roast_context` | `Green` · `Light` · `Medium` · `Dark` · `Light/Medium` · `Medium/Dark` |
| `grind_size` | `Espresso` · `Fine` · `Medium-Fine` · `Medium` · `Medium-Coarse` · `Coarse` |
| `method_type` | `pour_over` · `immersion` · `hybrid` · `pressure` · `espresso` |
| `defect_class` | `Healthy` · `Broken` · `Insect Damage` · `Quaker` · `Scorched` · `Foreign Matter` |

Enum yang **disimpan** memakai **Title Case** (kecuali `method_type` snake_case). Nilai di JSON seed harus mengikuti ini. `status` adalah nilai **turunan/tampilan** (tidak disimpan, tidak masuk seed). Kolom enum ditegakkan dengan **`CHECK` constraint** pada DDL (bukan hanya konvensi).

---

## 12. Migrasi & Versi

- Versi skema disimpan di `meta.schema_version`.
- `sqflite` `onCreate` membuat seluruh tabel untuk versi terkini.
- `onUpgrade` menerapkan migrasi bertingkat sesuai `schema_version`.
- Perubahan skema **wajib** menambah migrasi + menaikkan `schema_version`.
- Versi knowledge base disimpan terpisah di `meta.kb_version` (dapat diperbarui tanpa mengubah skema).

---

## 13. Format Seed

Sumber seed: `assets/knowledge/brewing_knowledge.json`.

```json
{
  "kb_version": "1.0",
  "methods": [
    { "method_id": "M001", "method_name": "V60",
      "method_type": "pour_over", "description": "..." }
  ],
  "recipes": [
    { "recipe_id": "R001", "method_id": "M001",
      "species": "Arabica", "quality_profile": "High",
      "roast_context": "Light/Medium", "dose_g": 15,
      "water_volume_ml": 225, "grind_size": "Medium-Fine",
      "temperature_c": 92, "brewing_time_s": 165,
      "source": "BR001", "is_default": 1,
      "notes": "Sesuaikan grind bila seduhan terlalu pahit.",
      "steps": [
        { "step_no": 1, "phase": "prep", "title": "Rinsing filter",
          "description": "...", "target_time": null },
        { "step_no": 2, "phase": "brew", "title": "Bloom",
          "description": "...", "target_time": "00:00–00:45" }
      ] }
  ]
}
```

Alur seed: `JSON → BrewingDataSource → BrewingRepository → SQLite`. Setelah itu SQLite menjadi satu-satunya sumber query runtime.

---

## 14. Aturan Integritas

1. `brew_recipes.method_id` harus ada di `brew_methods`.
2. `recommendations.primary_recipe_id` harus ada di `brew_recipes`; resep harus milik `primary_method_id`.
3. Satu `analysis` maksimal punya satu baris `recommendations`.
4. `analysis_defects` unik per (`analysis_id`, `defect_class`).
5. `analyses` dan turunannya dihapus berantai (`ON DELETE CASCADE`).
6. Nilai enum harus sesuai bagian 11; ditegakkan `CHECK` pada `brew_methods` (`method_type`), `brew_recipes` (`species`, `quality_profile`, `roast_context`, `grind_size`), `analyses` (`species`, `roast`, `quality_profile`), dan `analysis_defects` (`defect_class`).
7. `source` wajib terisi (traceability BR001–BR004).

---

## 15. Nilai Turunan & Nilai Dihitung

| Nilai | Asal | Disimpan? |
|---|---|---|
| `grade` | `quality_profile` (pemetaan D-02) | Tidak |
| Rasio | `water_volume_ml / dose_g` | Tidak |
| `status` (`uncertain`) | `roast_confidence` vs ambang | Tidak |
| `defect_rate` | hitung saat analisis (snapshot) | Ya |
| `roast_distribution` | agregasi batch saat analisis | Ya (JSON) |
