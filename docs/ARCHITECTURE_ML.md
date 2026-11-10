# ROASTMATE — ARSITEKTUR ML

Versi: 1.0 (compact)
Dokumen asli: `../../architecture_ml.md` (backup)

Prinsip: ML untuk **visual** (deteksi + klasifikasi). Quality score dan parameter seduh berasal dari **rule engine + knowledge base**, bukan model gambar.

---

## 1. Pipeline

```
TRAINING (offline, Kaggle)
Dataset → Manifest → Dedup MD5 → Split (stratified / group-aware)
→ Preprocessing (kontrak crop 224) → Train (Detector YOLOv8n + 3 Classifier MobileNetV3)
→ Evaluation (in-domain; lintas-sumber ditahan sampai DS010 tersedia) → Export TFLite (fp32)

INFERENCE (on-device)
Foto → Image Quality Check → Deteksi Biji (YOLOv8n) → Crop per Biji (pad ~10% → resize 224 bilinear)
→ Klasifikasi (Species → Roast → Defect) → Shape Analysis (OpenCV)
→ Batch Aggregation (defect_rate soft) → Quality Score → Quality Profile
→ Recommendation Engine → Knowledge Base Lookup
→ Metode + Grind + Air + Suhu + Waktu
```

> Arsitektur: **detector** = YOLOv8n; **classifier** (species/roast/defect) = **MobileNetV3-Small** (Keras/TF). Hasil aktual & metrik ada di `ML_PBL/ml/models/` (`metrics.json`).

---

## 2. Dataset

Dataset yang **benar-benar dipakai** untuk training (hasil `ML_PBL`). Dataset lain di Lampiran A berstatus "kandidat / belum dipakai" — bukan bagian dari model terlatih.

| ID | Nama | Fungsi | Tipe | Gambar | Kelas asli | Status |
|---|---|---|---|---|---|---|
| DS-SPECIES | Ultralytics `coffee-beans` | Species (M2) | klasifikasi | 1.913 (18 sesi) | Arabica, Liberika, Robusta | **Dipakai** |
| DS-ROAST | `gpiosenka/coffee-bean-dataset-resized-224-x-224` | Roast (M3) | klasifikasi | 1.600→1.194 (dedup MD5) | Green, Light, Medium, Dark | **Dipakai** |
| DS-DEFECT | `RoastedCoffeeDefectDataset` (`beans.csv`) | Defect (M4) | klasifikasi (roasted) | 1.130 | normal, quaker, frag, under, burnt, insectOrMold → digabung 4 | **Dipakai** |
| DS-DET | **Sintetis copy-paste** (biji tersegmentasi + background Unsplash) | Detector (M1) | object-detection | ±350 (25–60 biji/img) | bean | **Dipakai** |

### Ketentuan penting tiap dataset

- **DS-SPECIES** — didapat via Ultralytics (`coffee-beans`). Berisi 18 sesi
  (sumber foto berbeda) → evaluasi memakai **heldout-session** untuk angka jujur.
  Ada 3 kelas: `Arabica`, `Liberika`, `Robusta`. Kolom `Liberika` **dibuang saat
  inference** (renormalisasi A/R + gate `Mixed`) karena akurasinya rendah.
- **DS-ROAST** — `gpiosenka` coffee-bean-224. **Dedup MD5** menurunkan 1.600→1.194.
  Split **asli** bocor (test = duplikat train), jadi dilakukan **resample
  70/15/15 stratified**. `Green` adalah **salah satu dari 4 kelas roast** (bukan
  gerbang).
- **DS-DEFECT** — `RoastedCoffeeDefectDataset`. 6 label mentah digabung ke **4 kelas**
  (`Normal`/`Quaker`/`Broken`/`Severe`) karena skema `merged4` mengungguli `raw6`
  (sampel label minor terlalu sedikit). Ada kebocoran sesi: within-session 0.592 vs
  out-of-fold 0.779 (lihat §13).
- **DS-DET** — bukan dataset publik; **sintetis copy-paste** (biji tersegmentasi
  ditempel ke background Unsplash, ±350 gambar, 25–60 biji/gambar). Hanya 1 kelas
  `bean`. Ikut pola `kaggle_yolo/train_yolo.py`.

### Dataset lain (tidak dipakai saat training)

Daftar DS001–DS013 di **Lampiran A** adalah **kandidat/riwayat** dari plan lama.
Untuk hasil terlatih di `ML_PBL`, hanya DS-SPECIES / DS-ROAST / DS-DEFECT / DS-DET
di atas yang berlaku. Sisanya ditandai **belum dipakai / evaluasi berikutnya**.

---

## 3. Label Mapping

### Mapping label mentah → 4 kelas (M4 Defect)

Target M4 adalah **4 kelas**: `Normal` / `Quaker` / `Broken` / `Severe` (skema `merged4` menang vs `raw6`).

| Sumber | Label asli | → Target |
|---|---|---|
| DS-DEFECT | normal | `Normal` |
| DS-DEFECT | quaker | `Quaker` |
| DS-DEFECT | frag | `Broken` |
| DS-DEFECT | under | `Severe` |
| DS-DEFECT | burnt | `Severe` |
| DS-DEFECT | insectOrMold | `Severe` |

Catatan:
- `under` / `burnt` / `insectOrMold` digabung ke `Severe` karena sampel tiap label
  terlalu sedikit untuk dilatih terpisah. Sub-jenisnya direkonstruksi **saat render**
  dari kombinasi `Severe` + `roast` (lihat §15, `defect_interpretation`):
  - `Severe` + `Green`/`Light` → `underdeveloped`
  - `Severe` + `Dark` → `overroasted`
  - `Severe` + `Medium` → `contamination`
- **`Foreign Matter`** tidak diprediksi classifier; ditangani **detector** (bukan biji).

### Mapping label training ↔ enum aplikasi

Label target training memakai **snake_case**; enum yang disimpan di DB dan ditampilkan di UI memakai **Title Case**. Pemetaan wajib eksplisit:

| Target (training) | Enum DB/UI |
|---|---|
| `arabica` | `Arabica` |
| `liberika` | `Liberika` |
| `robusta` | `Robusta` |
| `mixed` | `Mixed` |
| `green` / `light` / `medium` / `dark` | `Green` / `Light` / `Medium` / `Dark` |
| `normal` / `quaker` / `broken` / `severe` | `Normal` / `Quaker` / `Broken` / `Severe` |

Catatan: `Foreign Matter` **tidak ada** di enum `analysis_defects` — benda asing ditangani detector.

### Hard Rules
- `burnt` ≠ otomatis `scorched` (keduanya → `Severe`).
- Grade A/B ≠ otomatis `Normal`.
- `Premium` ≠ otomatis `Normal`.

---

## 4. Split & Preprocessing

Split: **Train 70% · Val 15% · Test 15%** (stratified); bila sumber banyak sesi/grup → **group-aware split**.

Aturan:
- Split **sebelum** augmentation.
- Test set tidak masuk training.
- Test set tidak dipakai kalibrasi.
- Gunakan group/source-aware split bila perlu (DS-SPECIES, DS-DEFECT).

Preprocessing — **kontrak crop** (kontrak yang sama dipakai training + inference; lihat `ML_PBL/ml/models/PREPROCESS.md`):

```
deteksi → crop + margin (~10%) → resize 224 bilinear → float32 (rentang 0..255, TIDAK dinormalisasi)
```

Classifier diexport dengan `include_preprocessing=True`, sehingga **normalisasi ImageNet ada di dalam model**, bukan di sisi aplikasi.

| Aturan | Nilai |
|---|---|
| Bentuk input | `(1, 224, 224, 3)` **NHWC RGB** |
| Tipe & rentang | `float32`, `0..255` (jangan dinormalisasi sendiri) |
| Resize | **bilinear** (tf.image.resize bilinear == PIL BILINEAR), bukan nearest/LANCZOS |
| Warna | tanpa color-aug ekstrem (warna = fitur utama roast) |
| INT8 classifier | **ditolak** (rescaling `include_preprocessing` MobileNetV3 rusak saat quantize; agreement < 1.0) |

Augmentasi: rotation, flip, scale kecil, brightness, contrast, translation; **oklusi/tumpang-tindih** untuk detector sintetis.
**Pengecualian roast:** hindari perubahan warna ekstrem.

---

## 5. Model

| Model | Tugas | Arsitektur | Kelas | Dataset (latih → uji) |
|---|---|---|---|---|
| M1 Detector | Lokalisasi biji | YOLOv8n, input 640 | `bean` (1) | DS-DET (sintetis copy-paste) |
| M2 Species | Jenis | MobileNetV3-Small, 224 | Arabica / Liberika / Robusta (3) | DS-SPECIES |
| M3 Roast | Tingkat sangrai | MobileNetV3-Small, 224 | Green / Light / Medium / Dark (4) | DS-ROAST |
| M4 Defect | Cacat (4 kelas) | MobileNetV3-Small, 224 | Normal / Quaker / Broken / Severe (4) | DS-DEFECT |

Output deteksi → bounding box → crop (kontrak §4) → input klasifikasi.

Catatan:
- **Species = 3 kelas** (`Arabica`/`Liberika`/`Robusta`). Saat inference, kolom `Liberika` dibuang → A/R direnormalisasi + gate `Mixed` (lihat §8).
- **Roast = 4 kelas** (D-23 dibatalkan): `Green` adalah **kelas roast**, bukan gerbang.
- **Defect = 4 kelas**: `Normal`/`Quaker`/`Broken`/`Severe` (D-22 dibatalkan). `Foreign Matter` ditangani detector.
- Export classifier **hanya fp32**; INT8 classifier **ditolak** (agreement < 1.0). Hanya detector M1 yang diexport fp16/fp32/int8.

---

## 6. Shape Analysis (OpenCV)

Fitur per biji dihitung dari kontur/bbox (bukan ML): `area`, `perimeter`, `width`, `height`, `aspect_ratio`, `solidity`, `circularity`, `eccentricity`.

Dipakai untuk **uniformity bentuk**: `shape_uniformity = 1 − 2·std(solidity)` (dari `Bean` meta). Dimensi bbox juga jadi dasar estimator `bean_size` yang menurunkan `size_uniformity`.

---

## 7. Batch Aggregation

Metrik: `visible_beans`, `species` (dominan atau `Mixed`), `roast_distribution`, hitungan per kelas defect, `defect_rate`, `shape_uniformity`, `size_uniformity`, `roast_uniformity`.

```
defect_rate = Σ_biji (p_biji · weight) / n_biji      # soft: expected severity per biji
            = rata-rata skor severity terbobot setiap biji
```

- `p_biji · weight` = dot product distribusi prob 4 kelas defect ⊗ bobot severity (Normal 0.0 · Quaker 0.7 · Broken 0.3 · Severe 1.0).
- `visible_beans` = rasio luas area terhadap frame, **dibulatkan integer** untuk skema DB.
- Hanya biji **terlihat** yang dinilai; biji tertutup tidak dinilai.

---

## 8. Confidence & Mixed Batch

- Species: kolom `Liberika` dibuang, prob A/R direnormalisasi; bila confidence species < **0.70** → `Mixed`.
- Roast: bila confidence roast < **0.45** → status `uncertain`.
- Jangan memaksakan satu kelas saat confidence tidak memadai.

---

## 9. Quality Engine

Rule-based (bukan ML). Input utama: `defect_rate` (uniformity tetap dihitung & ditampilkan, tapi **tidak masuk rumus score**).

```
quality_score = round(100 × (1 − defect_rate))
```

- `defect_rate` = soft expected severity per biji (§7), memakai bobot severity:
  Normal 0.0 · Quaker 0.7 · Broken 0.3 · Severe 1.0.
- Skor 0–100 → Quality Profile: `High` ≥ 90 (dr ≤ 0.10) · `Medium` ≥ 70 (dr ≤ 0.30) · `Low` < 70.

Pemetaan ke Indicative Grade (default, dapat dikonfigurasi; **tidak** dihasilkan oleh `ML_PBL`, ini display-layer di aplikasi):

| Profile | Score | Grade |
|---|---|---|
| High | 85–100 | Specialty |
| High | 75–84 | Premium |
| Medium | 60–74 | Standard |
| Low | 40–59 | Below Standard |
| Low | 0–39 | Off Grade |

---

## 10. Brewing Knowledge Base

Knowledge base = dua tabel: `brew_methods` (deskriptif) dan `brew_recipes` (otoritatif). **Definisi skema, tipe, constraint, dan index lengkap ada di `DATABASE_SCHEMA.md`.**

Peran:
- `brew_methods` — metadata metode, **tidak** menyimpan parameter seduh.
- `brew_recipes` — pemilik seluruh parameter seduh: `dose_g`, `water_volume_ml`, `grind_size`, `temperature_c`, `brewing_time_s`, `source`, `is_default`, `steps` (JSON), `notes`.

Contoh metode: `M001 V60 pour_over` · `M002 French Press immersion` · `M003 AeroPress hybrid` · `M004 Moka Pot pressure` · `M005 Kopi Tubruk immersion`.

### Aturan
- Parameter seduh **hanya ada di `brew_recipes`**. Tidak diduplikasi di `brew_methods`.
- Nilai parameter **harus** berasal/diturunkan secara terdokumentasi dari sumber (BR001–BR004). Jangan mengarang parameter.
- Katalog metode menampilkan parameter dari resep `is_default = 1`.
- Langkah disimpan di `steps` JSON; tiap item punya `phase` (`prep` = persiapan & alat, `brew` = langkah seduh). Tips rasa disimpan di `notes`.
- Rasio **tidak disimpan**; dihitung `water_volume_ml / dose_g`.
- KB disimpan di **SQLite** (`DATABASE_SCHEMA.md`).

---

## 11. Recommendation Engine

Input: `species`, `quality_profile`, `defect_profile`, `roast_context`.

```
Analysis → Filter kandidat metode → Filter kandidat resep
→ Terapkan rules → Score kandidat → Pilih metode
→ Ambil parameter resep → Recommendation
```

Scoring (bukan IF-ELSE bertumpuk):

```
method_score = species_match + quality_match + profile_match + context_match
```

Bobot dapat dikonfigurasi tanpa retraining.

### Grind / Air / Suhu / Waktu
- Semua berasal dari **`brew_recipes`** (resep terpilih), bukan model visi.
- Diambil via `recipe_id` terpilih, termasuk `dose_g`, `water_volume_ml`, `temperature_c`, `brewing_time_s`, dan `source`.
- Grind disimpan sebagai kategori: Fine · Medium-Fine · Medium · Medium-Coarse · Coarse.
- Setting grinder numerik tidak universal antar grinder.

### Contoh rekomendasi
```
Arabica + High + Light/Medium → metode penonjol karakter
Robusta + Medium → metode body penuh
Low quality → metode lebih forgiving
```

---

## 12. Green Bean

`Green` adalah **kelas roast ke-4** (salah satu output M3), bukan gerbang terpisah (D-23 dibatalkan).

```
IF roast = Green
THEN tidak ada rekomendasi seduh normal; roasting diperlukan
```

- Model roast menghasilkan 4 kelas (`Green` / `Light` / `Medium` / `Dark`).
- `Green` tetap tercatat sebagai nilai `roast_context` di knowledge base agar resep/penanganan khusus bisa ditandai.

---

## 13. Evaluation

Angka dari hasil training `ML_PBL` (`ml/models/metrics.json`). Semua classifier = MobileNetV3-Small; detector = YOLOv8n.

### Detector (M1)
⚠️ **Belum terukur** — belum ada eval mAP di `ML_PBL`. Detector YOLOv8n dilatih sintetis (conf 0.30 / iou 0.45), export fp16 (default) / fp32 / int8, tetapi **belum ada laporan mAP50 / mAP50-95 / recall transfer**. Jangan memakai angka mAP dari doc lama (detector di sana beda).

### Classifier

| Model | Metrik utama | Recall per kelas | Catatan |
|---|---|---|---|
| M2 Species (3 kelas) | acc **0.7282** · macroF1 **0.7258** (n=287) | Arabica 0.818 · Liberika 0.573 · Robusta 0.796 | heldout-session bacc **0.7578**; gate 0.70 → 78.3% terjawab |
| M3 Roast (4 kelas) | acc **0.8771** · macroF1 **0.8665** (n=179) | Green 1.0 · Light 1.0 · **Medium 0.511** · Dark 1.0 | batas terlemah Medium↔Dark |
| M4 Defect (4 kelas) | acc **0.7847** · macroF1 **0.6083** | Normal 0.924 · Quaker 0.735 · Broken 0.457 · **Severe 0.284** | within-session 0.592 vs OOF 0.779 (kebocoran sesi) |

Catatan tambahan:
- **Species:** `Liberika` recall rendah (0.573) → kolom Liberika dibuang saat inference.
- **Roast:** `Medium` recall 0.511 (banyak salah ke Dark).
- **Defect:** `Severe` recall 0.284 (kelas paling sulit & langka); class_weight saat training Normal 0.531 / Quaker 0.712 / Broken 2.353 / Severe 3.465.
- **INT8 classifier:** species agreement 0.85 · roast 0.98 · defect 0.90 — **semua < 1.0 → ditolak**. Hanya fp32 yang lolos argmax-agreement 1.0.

### Kontrak & batch-level
- Kontrak crop: verifikasi resize bilinear & rentang input 0..255.
- Batch-level: Bean Count Error, Defect Rate Error, Species/Roast Agreement, Quality Score Error, Recommendation & Recipe Retrieval Consistency.

> Wajib dilaporkan tiap run: **in-domain DAN yang jujur (heldout-session / out-of-fold)**, recall per kelas, confusion, `n`.

---

## 14. Optimization & Target

```
Model terbaik → Export TFLite (fp32 classifier; detector fp16) → Benchmark
```

Bandingkan: accuracy, F1, latency, RAM, ukuran model.

| Target | Nilai | Catatan |
|---|---|---|
| Ukuran total model | ~17 MB | detector fp16 6.1 MB + 3× classifier fp32 (~3.6–3.7 MB tiap) |
| Latensi inference | < ~1 detik | 1 forward pass/biji; model dimuat bergantian |
| RAM | < ~120 MB | proses model satu per satu |

Catatan:
- **INT8 classifier ditolak** (agreement < 1.0). Ukuran total **~17 MB** membatalkan
  NFR lama "≤ ~4 MB" (itu asumsi plan lama yang tidak tercapai).

---

## 15. Result Object

```json
{
  "species": "Arabica",
  "roast": "Medium",
  "roast_confidence": 0.91,
  "roast_distribution": { "Green": 0, "Light": 3, "Medium": 19, "Dark": 2 },
  "visible_beans": 24,
  "defects": {
    "Normal": 20, "Quaker": 2, "Broken": 1, "Severe": 1
  },
  "defect_interpretation": "contamination",
  "defect_rate": 0.062,
  "shape_uniformity": 0.86,
  "size_uniformity": 0.88,
  "roast_uniformity": 0.9,
  "status": "OK",
  "quality_score": 94,
  "quality_profile": "High",
  "recommendation": {
    "primary_method": "V60",
    "alternative_method": "AeroPress",
    "dose_g": 15,
    "grind_size": "Medium-Fine",
    "water_volume_ml": 240,
    "temperature_c": 92,
    "brewing_time_s": 165,
    "reason": "Sesuai dengan profil kopi terdeteksi."
  }
}
```

Catatan:
- `defects` memakai **4 kelas** (`Normal`/`Quaker`/`Broken`/`Severe`), bukan biner.
- `defect_interpretation` adalah **nilai turunan** (bukan kolom DB) dari `Severe` + `roast`: `underdeveloped` (Green/Light) · `overroasted` (Dark) · `contamination` (Medium).
- `status` (`OK` / `Uncertain`) diturunkan dari confidence vs ambang, bukan kelas paksa.
- `quality_score` dihitung dari **defect only**: `100 × (1 − defect_rate)`.

---

## 16. Narrative Generation

Narasi hasil (`summaryText`, `reason`) dihasilkan **template lokal** dari angka hasil — **bukan** brewing knowledge base, **bukan** LLM. Satu mekanisme menangani keduanya (D-21).

| Field | Sumber | Disimpan? |
|---|---|---|
| `summaryText` | template dari angka hasil (roast, defect, uniformity, quality) | **Tidak** — diturunkan saat tampil |
| `reason` | template dari resep terpilih + profil hasil | **Ya** — `recommendations.reason` |

Aturan:

1. Bahasa **Indonesia** saja (selaras D-14).
2. `summaryText` diturunkan saat render (seperti `grade`/`status`), bukan kolom DB.
3. `reason` disimpan bersama rekomendasi agar riwayat tetap konsisten walau template berubah.
4. Template murni rule-based: tidak ada panggilan jaringan/model saat render.

---

## 17. Aturan Non-Negotiable (ringkas)

1. Jangan merge dataset buta-buta; jaga provenance & versi.
2. Test set tidak untuk training/kalibrasi.
3. Split sebelum augmentation.
4. Jangan map label berbeda tanpa justifikasi (`burnt`≠`scorched`, Grade A≠healthy, NG≠final).
5. Detector = YOLOv8n; classifier (species/roast/defect) = **MobileNetV3-Small** (Keras/TF). Defect = **4 kelas**; Roast = **4 kelas** (`Green` termasuk); Species = **3 kelas** + `Mixed` (D-22/D-23 dibatalkan).
6. Shape pakai CV, bukan ML.
7. Quality Score = rule engine; rekomendasi = KB + rules.
8. Grind/air/suhu/waktu berasal dari resep terpilih, bukan prediksi ML.
9. Green bean tanpa rekomendasi seduh normal.
10. Timer seduh interaktif out of scope.
11. Setiap eksperimen reproducible dari `experiment_registry.csv`.
12. Evaluasi detection & classification terpisah, plus batch-level & recommendation.
13. Rekomendasi utama = species + quality profile; roast/defect sebagai konteks.
14. **Satu kontrak crop** dipakai training & inference (`ml/preprocess.py`); crop training wajib identik dengan crop inference.

---

## Lampiran A — Sumber Dataset

| ID | Nama | URL Asli | URL Mirror |
|---|---|---|---|
| DS001 | USK-COFFEE Arabica | https://coffee.comvislab-usk.org/ | Kaggle: `ghazwanababil/usk-coffee-arabica` |
| DS002 | Coffee Bean Grading | https://huggingface.co/datasets/SamruddhK/coffee-bean-grading-dataset | — |
| DS003 | Coffee Bean 224×224 | — | Kaggle: `gpiosenka/coffee-bean-dataset-resized-224-x-224` |
| DS004 | RoastedCoffeeDefect | https://github.com/dont-text-me/RoastedCoffeeDefectDataset | Kaggle: `ghazwanababil/roastedcoffeedefectdataset` |
| DS005 | Coffee Bean Defect — NG | Roboflow: `roasted-coffee-bean-defect-detectionandy/coffee-bean-defect` | — |
| DS006 | Kopi Robusta dan Arabika | Roboflow: `tugas-akhir-8wmr1/kopi-robusta-dan-arabika` | — |
| DS007 | Robusta Coffee Bean Defects | Roboflow: `roasted-coffee-bean-defect/robusta-coffee-bean-defects` | — |
| DS008 | ROBUSTA DATASET UNCROPPED | Roboflow: `renies-workspace/robusta-dataset-uncropped` | — |
| DS009 | Coffee Beans Dataset 2 (Seg) | Roboflow: `new-workspace-cuswj/coffee-beans-dataset-2-segmentation` | — |
| DS010 | Custom Mobile Batch | Dibuat tim Roastmate | — |
| DS011 | Coffee Color (roast-coffee) | Roboflow: `roast-coffee/coffee-color` | — |
| DS012 | Roasted Coffee Bean 300 | Roboflow: `bai-pang/roasted-coffee-bean-300` | — |
| DS013 | Arabica/Robusta (dulu KANDIDAT-B) | Roboflow Universe (provenance belum terverifikasi) | — |

Catatan: DS001–DS013 = daftar riwayat/kandidat dari plan lama. **Model terlatih di `ML_PBL` hanya memakai 4 sumber** (lihat §2): Ultralytics `coffee-beans` (species), `gpiosenka` coffee-bean-224 (roast), `RoastedCoffeeDefectDataset` (defect), dan komposit sintetis copy-paste (detector). Sisanya **belum dipakai**.

Catatan: lampiran ini jembatan sementara. Saat `dataset_registry.csv` dibuat, URL mentah menjadi sumber kebenaran tunggal dan lampiran ini cukup merujuk padanya.

---

## Lampiran B — Sumber Brewing

| ID | Nama | URL |
|---|---|---|
| BR001 | andmos/Coffee | https://github.com/andmos/Coffee |
| BR002 | BrewSpec | https://brewspec.coffee/ |
| BR003 | Coffee Master Recipes | https://coffeemaster.app/recipes |
| BR004 | afrians19/coffee-app | https://github.com/afrians19/coffee-app |
