# ROASTMATE — ARSITEKTUR MOBILE

Versi: 1.0
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
| Inference | `tflite_flutter` (model INT8) |
| Kamera | `camera` |
| Computer vision (shape) | OpenCV (via FFI/binding) |
| Penyimpanan lokal | `sqflite` (SQLite) |
| State management | Riverpod / Provider (satu pilihan, konsisten) |
| Ikon & font | Material Icons + Inter |

---

## 3. Struktur Folder `lib/`

```
lib/
├── main.dart
├── core/            # tema, token, konstanta, util
├── data/            # model data, repository, sumber lokal
├── domain/          # entitas & use case
├── engines/         # quality engine, recommendation engine, aggregator
├── inference/       # loader model, detector, classifier, shape
└── features/
    ├── home/
    ├── analysis/     # riwayat + detail inspeksi
    ├── brew/         # katalog + detail resep
    └── scan/         # kamera + image quality check
```

---

## 4. Layer & Aliran Data

```
UI (widget)
  ↓ baca state
State / Controller
  ↓ panggil
Use Case / Engine
  ↓ akses
Repository  →  Sumber lokal (SQLite, assets, model file)
```

Aturan:
- UI tidak memanggil inference/model langsung.
- Engine (quality, recommendation) murni & tidak bergantung UI.
- Knowledge base = data lokal (assets/SQLite), bukan kode.

---

## 5. Navigasi & Layar

| Tab / Alur | Layar | Mockup |
|---|---|---|
| Beranda | Beranda | `Beranda.png` |
| Beranda → Scan | Scan Kamera | `Scan Kamera.png` |
| Scan → Hasil | Detail Inspeksi | `Hasil Analisis.png` |
| Analisis | Riwayat Analisis | `Riwayat Analisis.png` |
| Seduh | Katalog Metode | `Resep Seduh.png` |
| Seduh → detail | Detail Resep (panduan statis) | `Detail Resep.png` |
| Referensi | Design System | `Design System.png` |

Bottom navigation: **Beranda · Analisis · Seduh**.

---

## 6. Alur Inference On-Device

```
Kamera → Image Quality Check
  ├─ gagal → tampilkan peringatan, berhenti
  └─ lolos ↓
Deteksi biji (YOLOv8n Detection) → crop per biji
  → Klasifikasi species / roast / defect (3 model Cls)
  → Shape analysis (OpenCV)
  → Batch Aggregation
  → Quality Engine → Quality Profile
  → Recommendation Engine → KB lookup
  → Simpan ke SQLite → tampilkan Hasil
```

Catatan:
- Jalankan inference di **isolate** agar UI tetap responsif.
- Proses model **satu per satu** untuk menekan puncak RAM.
- Tidak ada timer interaktif di alur mana pun.

---

## 7. Model Assets

| File | Fungsi | Format |
|---|---|---|
| `detector.tflite` | Deteksi biji | INT8 |
| `species.tflite` | Species | INT8 |
| `roast.tflite` | Roast | INT8 |
| `defect.tflite` | Defect | INT8 |
| `brew_methods.*` | Knowledge base metode | JSON/SQLite |
| `brew_recipes.*` | Knowledge base resep | JSON/SQLite |

Aturan: model dibundel sebagai asset; dimuat sekali saat dibutuhkan lalu dibebaskan untuk menekan RAM.

---

## 8. Penyimpanan Riwayat (SQLite)

| Tabel | Kolom utama |
|---|---|
| `analyses` | id, nama, tanggal, species, roast, visible_beans, defect_rate, quality_score, quality_profile, grade |
| `analysis_defects` | analysis_id, kelas, jumlah |
| `recommendations` | analysis_id, primary_method, alternative_method, grind, water_ml, temp_c, time_s |
| `brew_methods` | method_id, nama, tipe, ringkasan, rasio, waktu, grind, suhu |
| `brew_recipes` | recipe_id, method_id, species, quality_profile, roast_context, parameter, source |

---

## 9. Mapping Design Token → Dart

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

## 10. States

| State | Perilaku |
|---|---|
| Loading | Indikator progres saat inference |
| Empty | Pesan ramah + CTA (mis. belum ada riwayat) |
| Error | Pesan jelas + aksi ulang |
| Image ditolak | Peringatan kualitas foto + minta ulang |
| `uncertain` | Tampilkan status ketidakpastian, bukan kelas paksa |
| Green bean | Info "perlu roasting", tanpa parameter seduh |

---

## 11. Target Performa

| Metrik | Target |
|---|---|
| Latensi inference | < ~1 detik |
| RAM | < ~120 MB |
| Ukuran model total | ≤ ~4 MB (perlu dikaji ulang) |
| Respons UI | Tetap mulus saat inference (isolate) |

---

## 12. Testing

- Unit: quality engine, recommendation engine, aggregator, confidence handling.
- Widget: layar utama (Beranda, Riwayat, Detail Inspeksi, Detail Resep).
- Integrasi: alur scan → hasil → simpan → tampil di riwayat.
- On-device: latensi & RAM pada perangkat nyata.
- Data: validasi output terhadap DS010 (custom mobile batch).
