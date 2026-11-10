# ROASTMATE — ARSITEKTUR MOBILE

Versi: 1.1
Fokus: peta & keputusan arsitektur (bukan tutorial kode).

---

## 1. Prinsip & Constraint

- **On-device:** seluruh inference berjalan di perangkat, tanpa internet.
- **Offline-first:** riwayat & knowledge base tersimpan lokal.
- **Privasi:** foto tidak pernah dikirim ke server.
- **Cepat:** inference < ~1 detik, RAM < ~120 MB.
- **Satu alur utama:** Beranda → Scan → Hasil → Resep.

---

## 2. Tech Stack

| Kebutuhan | Pilihan |
|---|---|
| Framework | Flutter (Dart) |
| Arsitektur presentasi | MVVM (View + ViewModel + Riverpod) |
| State & DI | Riverpod |
| Navigasi | GoRouter |
| Inference | `tflite_flutter` (classifier fp32 + detector fp16) |
| Kamera | `camera` |
| Computer vision (shape) | OpenCV (via FFI/binding) |
| Penyimpanan lokal | `sqflite` (SQLite) |
| Ikon & font | Material Icons + Inter |

---

## 3. Struktur Folder `lib/`

Feature-first: tiap fitur membawa `presentation / domain / data` sendiri.

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/          # app_router.dart (GoRouter)
│   └── providers/       # provider global
├── core/                # tema, token, konstanta, error, util, widget bersama
├── engines/             # quality engine, recommendation engine, aggregator
├── inference/           # loader model, detector, classifier, shape (OpenCV)
├── shared/              # model & enum lintas fitur
└── features/
    ├── home/            # beranda
    ├── scan/            # kamera + image quality check
    ├── result/          # detail inspeksi
    ├── analysis/        # riwayat
    └── brew/            # katalog + detail resep
```

Setiap fitur mengikuti pola:

```
features/<fitur>/
├── presentation/   # views/, viewmodels/, widgets/
├── domain/         # entities/, usecases/
└── data/           # repositories/, sources/
```

---

## 4. Layer & Aliran Data

```
PRESENTATION   View + ViewModel (Riverpod)
      ↓
DOMAIN         Use Case + Engine + Entity
      ↓
DATA           Repository → Local Data Source
      ↓
SQLite / Assets (model .tflite)
```

Aturan:
- UI tidak memanggil inference/model langsung.
- Engine (quality, recommendation) murni & tidak bergantung UI.
- Knowledge base diakses lewat repository, bukan query langsung dari UI.
- Satu arah: Presentation → Domain → Data.

---

## 5. Fitur & Tanggung Jawab Layar

| Fitur | Tanggung jawab |
|---|---|
| **Home** | Statistik ringkas, CTA Scan, shortcut katalog & riwayat |
| **Scan** | Inisialisasi kamera, capture batch, validasi gambar, jalankan analisis, simpan hasil |
| **Result** | Tampilkan hasil analisis (tidak menjalankan ML/recommendation sendiri) |
| **Analysis** | Daftar riwayat, filter species, ekspor CSV |
| **Brew** | Katalog metode, detail resep (panduan statis) |

Alur tiap fitur:

```
Home    → HomeView → HomeViewModel → StatisticsUseCase
Scan    → ScanView → ScanViewModel → AnalyzeCoffeeBatchUseCase → AnalysisPipeline
Result  → ResultView → ResultViewModel → AnalysisResult
Brew    → BrewView → BrewViewModel → BrewingRepository
```

Result menampilkan: species, roast, quality score, quality profile, ringkasan defect, rekomendasi seduh, dan parameter resep.

---

## 6. Navigasi & Routes

Bottom navigation **3 tab**: Beranda · Analisis · Seduh.
Scan adalah layar yang di-push dari Beranda (bukan tab).

```
BERANDA
 ├── (push) SCAN → RESULT → BREW METHOD DETAIL
 ├── ANALISIS (tab) → RIWAYAT → DETAIL INSPEKSI
 └── SEDUH (tab) → KATALOG METODE → DETAIL RESEP
```

Routes (GoRouter):

```
/home
/scan
/result/:analysisId
/history
/history/:analysisId
/brewing
/brewing/:methodId
```

---

## 7. Camera & ML Inference Layer

Kamera:

```
ScanView → CameraViewModel → CameraService → Camera Plugin
```

`CameraService` hanya menangani: `initialize()`, `preview()`, `capture()`, `dispose()`.

Model assets (`assets/models/`):

| File | Fungsi | Format |
|---|---|---|
| `bean_detection.tflite` | Deteksi biji (YOLOv8n) | fp16 (default; tersedia fp32/int8) |
| `species_classifier.tflite` | Species (Arabica / Liberika / Robusta) | fp32 |
| `roast_classifier.tflite` | Roast (Green / Light / Medium / Dark) | fp32 |
| `defect_classifier.tflite` | Defect (Normal / Quaker / Broken / Severe) | fp32 |

> Classifier hanya diexport **fp32** (INT8 ditolak — agreement < 1.0). Hanya detector yang punya varian fp16/int8. `Green` bukan model terpisah: ia adalah salah satu kelas roast.

Service inference: `BeanDetectionService`, `SpeciesInferenceService`, `RoastInferenceService`, `DefectInferenceService`.

Aturan: model dibundel sebagai asset; dimuat saat dibutuhkan lalu dibebaskan untuk menekan RAM. Knowledge base **bukan** asset runtime (lihat bagian 10).

---

## 8. Alur Inference On-Device

```
Captured Image
      ↓
Image Quality Check
  ├─ gagal → peringatan, berhenti
  └─ lolos ↓
Bean Detection (YOLOv8n) → Bean Crops (pad ~10% → resize 224 bilinear)
      ↓
Species / Roast / Defect Inference (3 / 4 / 4 kelas)
      ↓
Shape Analysis (OpenCV)
      ↓
Batch Aggregation
      ↓
Quality Engine → Quality Profile
      ↓
Recommendation Engine → KB lookup (SQLite)
      ↓
AnalysisResult → simpan → ResultView
```

Catatan:
- Jalankan inference di **isolate** agar UI tetap responsif.
- Proses model **satu per satu** untuk menekan puncak RAM.
- Species: kolom `Liberika` dibuang saat inference → A/R direnormalisasi; confidence < 0.70 → `Mixed`.
- Tidak ada timer interaktif di alur mana pun.

---

## 9. Penyimpanan (SQLite)

Seluruh data lokal berada di satu database SQLite, terbagi dua kelompok. **Skema lengkap (DDL, tipe, constraint, index, migrasi, format seed) ada di `DATABASE_SCHEMA.md`.**

### Knowledge base (statis, read-only saat runtime)

| Tabel | Peran |
|---|---|
| `brew_methods` | Deskriptif — metadata metode |
| `brew_recipes` | Otoritatif — seluruh parameter seduh + provenance |

### Riwayat analisis (dinamis, ditulis saat runtime)

| Tabel | Peran |
|---|---|
| `analyses` | Satu sesi analisis batch (termasuk `annotated_image_path`, `roast_distribution`) |
| `analysis_defects` | Rincian defect per analisis |
| `recommendations` | Rekomendasi per analisis (referensi resep) |
| `meta` | Internal — `schema_version`, `kb_version` |

Aturan: parameter seduh **tidak diduplikasi** di `recommendations` — cukup simpan `primary_recipe_id`, lalu ambil parameter dari `brew_recipes`. Ini mencegah inkonsistensi data.

---

## 10. Knowledge Base Seeding

```
App pertama dijalankan
      ↓
Create tables → Run migrations
      ↓
Seed knowledge base
      ↓
Application ready
```

Seed dari file bundel `assets/knowledge/brewing_knowledge.json`:

```json
{ "kb_version": "1.0", "methods": [], "recipes": [] }
```

```
JSON → BrewingDataSource → BrewingRepository → SQLite
```

Setelah itu SQLite menjadi satu-satunya sumber query saat runtime. Tidak ada KB berbentuk asset JSON yang dibaca saat runtime.

---

## 11. Repository & Providers

Repository:

```
ScanRepository
HistoryRepository
BrewingRepository
SettingsRepository
```

`BrewingRepository` adalah satu-satunya akses ke `brew_methods` + `brew_recipes`. **Katalog dan Recommendation Engine memakai repository & data yang sama** — tidak boleh ada data brewing terpisah.

```
BrewingCatalog ─┐
                ├─→ BrewingRepository → SQLite
Recommendation ─┘
```

Riverpod providers minimum:

```
cameraServiceProvider      mlServiceProvider
analysisPipelineProvider   qualityEngineProvider
brewingRepositoryProvider  brewingCatalogProvider
brewingRecommendationProvider
scanRepositoryProvider     historyRepositoryProvider
```

---

## 12. Result Data Model

```
AnalysisResult
├── CoffeeProfile      { species, roast, roastDistribution, status }
├── BatchAnalysis      { visibleBeans, defectDistribution, shapeUniformity,
│                        sizeUniformity, roastUniformity }
├── QualityResult      { score, profile }
├── BrewingRecommendation
│   ├── primaryMethod, alternativeMethod
│   ├── doseG, grindSize, waterVolume, temperature, brewingTime
│   └── reason
└── summaryText        (derived at display; not stored)
```

Parameter seduh pada `BrewingRecommendation` berasal dari `brew_recipes` terpilih, bukan dari model.

`status` (`OK`/`Uncertain`) diturunkan dari `roast_confidence`, bukan kelas paksa. `annotated_image_path` disimpan terpisah untuk bukti visual.

`defectDistribution` memakai **4 kelas** (`Normal`/`Quaker`/`Broken`/`Severe`). Narasi sub-jenis parah (`underdeveloped`/`overroasted`/`contamination`) adalah **nilai turunan** `defect_interpretation` dari `Severe` + `roast` — tidak disimpan (lihat `DATABASE_SCHEMA.md` §15).

`summaryText` **diturunkan saat tampil** dari angka hasil (template lokal, D-21) — tidak ada kolom DB. `reason` disimpan di `recommendations.reason`.

---

## 13. Mapping Design Token → Dart

| Token (DESIGN.md) | Konstanta Dart |
|---|---|
| `brand-espresso` #5A382C | `RoastmateColors.primary` |
| `brand-terracotta` #8B5E3C | `RoastmateColors.secondary` |
| `brand-sage` #5E6B4A | `RoastmateColors.tertiary` |
| `surface-background` #F7F3EE | `RoastmateColors.background` |
| `surface-primary` #FFFDF9 | `RoastmateColors.surface` |
| `defect-*` | `RoastmateColors.defect[...]` |
| `grade-*` | `RoastmateColors.grade[...]` |
| Inter + skala tipografi | `RoastmateText` |
| radius & spacing | `RoastmateRadius`, `RoastmateSpacing` |

Aturan: warna/tipografi hanya dari token; jangan hardcode hex di widget.

---

## 14. States & Error Handling

State UI:

| State | Perilaku |
|---|---|
| Loading | Indikator progres saat inference |
| Empty | Pesan ramah + CTA (mis. belum ada riwayat) |
| Error | Pesan jelas + aksi ulang |
| Image ditolak | Peringatan kualitas foto + minta ulang |
| `uncertain` | Tampilkan status ketidakpastian, bukan kelas paksa |
| Green bean | Info "perlu roasting", tanpa parameter seduh |

Error yang ditangani:

```
CameraPermissionError      CameraInitializationError
InvalidImageError          NoBeanDetectedError
ModelLoadError             ModelInferenceError
LowConfidenceError         MixedBatchError
DatabaseError              BrewingDataError
RecommendationError
```

---

## 15. Offline-First

Fungsi inti berjalan tanpa internet: Scan, ML inference, quality assessment, Brewing Catalog, Brewing Recommendation, History.

Komponen lokal:

```
Flutter App
├── TFLite Models
├── OpenCV
├── Quality Engine
├── Brewing Knowledge Base
└── SQLite
```

---

## 16. Target Performa

| Metrik | Target |
|---|---|
| Latensi inference | < ~1 detik |
| RAM | < ~120 MB |
| Ukuran model total | ~17 MB (detector fp16 6.1 + 3× classifier fp32) |
| Respons UI | Tetap mulus saat inference (isolate) |

---

## 17. Testing

- **Unit:** QualityEngine, BrewingRecommendationEngine, BrewingCatalogUseCase, BatchAggregationService, ShapeAnalysisService, ViewModel, Repository.
- **Widget:** Beranda, Scan, Detail Inspeksi, Riwayat, Katalog Seduh, Detail Resep.
- **Integrasi:** Capture → ML → Quality → Recommendation → SQLite → Result.
- **On-device:** latensi & RAM pada perangkat nyata.
- **Data:** validasi output terhadap DS010 (custom mobile batch).
