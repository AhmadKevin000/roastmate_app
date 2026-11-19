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
| Auth & database cloud | Supabase (`supabase_flutter`) — login + sync riwayat (D-29) |
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
Result  → ResultView → ResultViewModel → AnalysisRepository.getDetail(id, join KB)
Brew    → BrewView → BrewViewModel → BrewingRepository
```

Result menampilkan: species, roast, quality score, quality profile, ringkasan defect, rekomendasi seduh, parameter resep, foto analisis (`analyses.image_path`), dan `summaryText` (di-generate saat baca, D-20).

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
/brewing/new
/brewing/user/:recipeId
/brewing/:methodId
```

`/result/:analysisId` & `/history/:analysisId`: segmen di-`int.tryParse`. Id valid → detail dibaca dari SQLite; segmen non-int (mis. `draft` dari alur scan) → data in-memory dari `state.extra` (fallback, AC-04).
`/brewing/new`: form tambah resep user (di luar shell — push penuh, seperti `/scan`); resep disimpan di `user_brew_recipes` (Plan 4).
`/brewing/user/:recipeId`: Detail Resep Kamu (di luar shell — push penuh); dibaca dari `user_brew_recipes` per id. Dideklarasikan **sebelum** `/brewing/:methodId`.
Tombol tambah resep Seduh adalah **FAB** di `MainShell` (hanya saat path eksak `/brewing`); ikon `+` di header sudah dihapus (v6).

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
- Species: kelas output mengikuti taksonomi ML_PBL — `Arabica`/`Liberika`/`Robusta` dipertahankan (D-27); confidence < 0.70 → `Mixed`.
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

Repository (yang sudah ada di kode):

```
AnalysisRepository   (riwayat: analyses + analysis_defects)
BrewingRepository    (katalog: brew_methods + brew_tools + brew_recipes;
                      resep user: user_brew_recipes — Plan 4)
HomeRepository       (ringkasan Beranda dari analyses)
```

`ScanRepository` / `HistoryRepository` / `SettingsRepository` belum ada; alur capture
(`scan_view`) orkestrasi: template acak → `RecommendationResolver` →
`AnalysisRepository.insertResult` (analyses + defects + recommendations, satu
transaksi) → upload foto **best-effort** via `CloudinaryService` (sukses:
`image_path` di-UPDATE ke `secure_url`; gagal/offline: tetap path lokal).
`CloudinaryService` (`core/network`) membaca kredensial dari `.env` via
`flutter_dotenv`; paket `cloudinary` (Dart) dipakai karena `cloudinary_flutter`
(semu versi) hanya widget/URL-gen tanpa API upload.
`BrewingRepository` adalah satu-satunya akses ke `brew_methods` + `brew_recipes`. **Katalog dan Recommendation Engine memakai repository & data yang sama** — tidak boleh ada data brewing terpisah.

Sejak v4, `BrewingRepository` juga mengakses `user_brew_recipes` (resep user)
via `getUserRecipes` / `insertUserRecipe` / `deleteUserRecipe`. Resep user
**tidak** ikut lookup rekomendasi maupun reseed KB (tabel terpisah).

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
homeRepositoryProvider
```

`AnalysisRepository` saat ini dibangun langsung dari `AppDatabase` di layar
riwayat (belum ada provider tersendiri).

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

**Pembacaan detail:** layar Detail Inspeksi fetch **per `analysisId`** dari SQLite — `AnalysisRepository.getDetail(id)` → `AnalysisDetail { result (analyses + analysis_defects), imagePath, recommendation + alternatives (join `recommendations` × `brew_methods`/`brew_recipes`), summaryText (runtime, D-20) }`. Route `draft` atau baca DB gagal → fallback in-memory (route extra) dari alur scan.

**Foto analisis** (`analyses.image_path`) dirender lewat widget bersama `AnalysisImage` — support URL Cloudinary + path lokal; thumbnail di list (Beranda/Riwayat) memakai transformasi resize `c_fill` (helper `cloudinaryThumbnailUrl`). **Gambar KB** (metode/alat, `assets/images/`) tetap aset lokal `Image.asset` — tidak di-upload/di-serve Cloudinary.

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

---

## 18. Auth & Sync (D-29)

Fitur akun + sinkronisasi riwayat antar device. **Auth gate (D-30):** tanpa
sesi login, app selalu berawal di layar login/daftar — fitur utama tidak bisa
diakses sebelum login. Setelah login, alur analisis tetap offline; sync murni
best-effort.

### Komponen

```
core/auth/         AuthController (Riverpod) — session Supabase, login/register/logout
core/network/      SupabaseService — klien Supabase dari .env
features/auth/     LoginScreen, RegisterScreen, ProfileScreen + ViewModel
features/sync/     SyncService — push pending + pull remote, dijalankan saat login & app resume
```

### Alur

```
App start → AuthGate: sesi Supabase ada?
  ├─ Ya → route fitur utama (Beranda dkk.)
  └─ Tidak → redirect /login (auth gate, D-30)
Login sukses → SyncService.run()
  ├─ Push: baris sync_status='pending' → upsert cloud by uuid → tandai 'synced'
  ├─ Backfill: baris lama tanpa uuid → beri UUID v4 + 'pending' sebelum push
  └─ Pull: baris cloud milik user yang uuid-nya belum ada lokal → insert (sync_status='synced')
Scan selesai (login aktif) → insert lokal dengan uuid + 'pending' → sync best-effort
Logout → hapus sesi → redirect /login (riwayat lokal tetap; sync berhenti)
```

### Aturan

- **Auth gate (D-30):** redirect deklaratif di GoRouter — listen `authControllerProvider`; route fitur memerlukan sesi, `/login` & `/register` hanya untuk tanpa sesi.
- **Kunci lintas device = `uuid`** (UUID v4). PK lokal `AUTOINCREMENT` tetap.
- Tabel sync: `analyses`, `analysis_defects`, `recommendations`, `user_brew_recipes`.
- Merge **union by uuid** (append-only); tidak ada konflik update. Delete di-propagate best-effort, tanpa tombstone.
- Referensi KB di cloud = ID mentah tanpa FK; resolusi ulang dari KB lokal.
- RLS Supabase menegakkan kepemilikan per user; UI hanya menyimpan `user_id` = `auth.users.id`.
- Kredensial di `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); `.env` gitignored, contoh di `.env.example`.
- Skema cloud: `DATABASE_SCHEMA.md` §16.

### Testing

- Unit: merge/pull logic (pure Dart, tanpa network), UUID backfill, mapping row ↔ model.
- Widget: Login/Register/Profile (validasi email-sandi, pesan error).
- Integrasi: insert pending → push (mock Supabase) → status `synced`; pull idempoten (uuid duplikat tidak diinsert ganda).
