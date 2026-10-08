# ROASTMATE — ARSITEKTUR ML

Versi: 1.0 (compact)
Dokumen asli: `../../architecture_ml.md` (backup)

Prinsip: ML untuk **visual** (deteksi + klasifikasi). Quality score dan parameter seduh berasal dari **rule engine + knowledge base**, bukan model gambar.

---

## 1. Pipeline

```
TRAINING
Dataset → Registry → Cleaning → Label Mapping → Split
→ Preprocessing → Train YOLOv8n (4 model) → Evaluation
→ Model Selection → Export Mobile → INT8 Quantization

INFERENCE (on-device)
Foto → Image Quality Check → Deteksi Biji → Crop per Biji
→ Klasifikasi (Species/Roast/Defect) → Shape Analysis (OpenCV)
→ Batch Aggregation → Quality Engine → Quality Profile
→ Recommendation Engine → Knowledge Base Lookup
→ Metode + Grind + Air + Suhu + Waktu
```

---

## 2. Dataset

| ID | Nama | Fungsi | Kelas asli | Status |
|---|---|---|---|---|
| DS001 | USK-COFFEE Arabica | Green Arabica, morfologi, bentuk | Peaberry, Longberry, Premium, Defect | Core |
| DS002 | Coffee Bean Grading | Segmentasi, polygon, grading | Grade A–D | Core |
| DS003 | Coffee Bean 224×224 | Roast classification | Green, Light, Medium, Dark | Core |
| DS004 | RoastedCoffeeDefect | Defect roasted | frag, insect, quaker, burnt, mold, under | Core |
| DS005 | Coffee Bean Defect — NG | Deteksi defect biner | NG | Supplemental |
| DS006 | Kopi Robusta dan Arabika | Species + roast (gap coverage) | Arabica/Robusta × Light/Medium/Dark | Core tambahan |
| DS007 | Robusta Coffee Bean Defects | Defect robusta | Black, Insect damage, Quaker, Scorched | Core tambahan |
| DS008 | ROBUSTA DATASET UNCROPPED | Defect + good reference | good, broken-chipped-cut, foreign-matters, severe/slight-insect-damage | Core tambahan |
| DS009 | Coffee Beans Dataset 2 (Seg) | Segmentasi alternatif | — | Alternatif |
| DS010 | Custom Mobile Batch | Validasi real-world | — | Wajib (eval) |

URL sumber lengkap (asli + mirror) ada di **Lampiran A**.

### Aturan provenance
- Simpan URL asli, URL mirror (Kaggle), versi/revisi, tanggal akses.
- Bedakan **sumber asli** vs **mirror**.
- Jangan merge dataset tanpa pengecekan duplicate/leakage.
- DS009 jangan digabung ke DS008 sebelum cek provenance (taxonomy mirip).

### Catatan bias
- DS003: cek bias origin/variety/kamera/background/lighting.
- DS002: species di halaman sumber belum tentu valid sebagai ground truth.
- DS006 tidak punya kelas `Green` → roast robusta hijau tidak terwakili.

---

## 3. Label Mapping

| Dataset | Label asli | Target | Aksi |
|---|---|---|---|
| DS004 | frag | broken | Map |
| DS004 | insect | insect_damage | Map |
| DS004 | quaker | quaker | Map |
| DS004 | burnt | — | **EXCLUDED** |
| DS004 | mold | — | **EXCLUDED** |
| DS004 | under | — | **EXCLUDED** |
| DS007 | Insect damage | insect_damage | Map |
| DS007 | Quaker | quaker | Map |
| DS007 | Scorched | scorched | Map |
| DS007 | Black | — | EXCLUDED |
| DS008 | good | healthy | Map |
| DS008 | broken-chipped-cut | broken | Map |
| DS008 | foreign-matters | foreign_matter | Map |
| DS008 | severe/slight-insect-damage | insect_damage | Map |

### Mapping label training ↔ enum aplikasi

Label target training memakai **snake_case**; enum yang disimpan di DB dan ditampilkan di UI memakai **Title Case**. Pemetaan wajib eksplisit:

| Target (training) | Enum DB/UI |
|---|---|
| `healthy` | `Healthy` |
| `broken` | `Broken` |
| `insect_damage` | `Insect Damage` |
| `quaker` | `Quaker` |
| `scorched` | `Scorched` |
| `foreign_matter` | `Foreign Matter` |

### Hard Rules
- `burnt` ≠ otomatis `scorched`.
- Grade A/B ≠ otomatis `healthy`.
- `Premium` ≠ otomatis `healthy`.
- `NG` bukan taxonomy defect final.

---

## 4. Split & Preprocessing

Split: **Train 70% · Val 15% · Test 15%**

Aturan:
- Split **sebelum** augmentation.
- Test set tidak masuk training.
- Test set tidak dipakai kalibrasi quantization.
- Gunakan group/source-aware split bila perlu.
- Dokumentasikan split di `experiment_registry.csv`.

Preprocessing umum: RGB → resize sesuai YOLOv8n → normalize.

Augmentasi: rotation, flip, scale kecil, brightness, contrast, translation.
**Pengecualian roast:** hindari perubahan warna ekstrem (warna = fitur utama roast).

---

## 5. Model

| Model | Tugas | Kelas | Dataset |
|---|---|---|---|
| YOLOv8n Detection | Lokalisasi biji | `bean` | DS002 + DS007 + DS008 |
| YOLOv8n-Cls | Species | Arabica / Robusta | DS001 + DS006 |
| YOLOv8n-Cls | Roast | Green / Light / Medium / Dark | DS003 + DS006 |
| YOLOv8n-Cls | Defect | Healthy, Broken, Insect Damage, Quaker, Scorched, Foreign Matter | DS004 + DS007 + DS008 |

Output deteksi → bounding box → crop → input klasifikasi.

---

## 6. Shape Analysis (OpenCV)

Fitur per biji: `area`, `perimeter`, `width`, `height`, `aspect_ratio`, `circularity`, `solidity`, `eccentricity`.

---

## 7. Batch Aggregation

Metrik: `visible_beans`, `species` (dominan), `roast_distribution`, hitungan per kelas defect, `defect_rate`, `shape_uniformity`, `size_uniformity`, `roast_uniformity`.

```
defect_rate = total_defective_beans / total_visible_beans
```

Aturan: hanya biji **terlihat** yang dinilai; biji tertutup tidak dinilai.

---

## 8. Confidence & Mixed Batch

- Confidence < threshold → `uncertain`.
- Distribusi species terlalu dekat → species `Mixed`; distribusi roast terlalu dekat → status `uncertain`.
- Jangan memaksakan satu kelas saat confidence/distribusi tidak memadai.

---

## 9. Quality Engine

Rule-based (bukan ML). Input: `defect_rate`, `shape_uniformity`, `size_uniformity`, `roast_uniformity`.

```
quality_score =
  w1 * defect_component +
  w2 * shape_component +
  w3 * size_component +
  w4 * roast_component
```

Bobot default (dapat dikonfigurasi):

| Komponen | Bobot |
|---|---|
| defect | 0.40 |
| shape | 0.20 |
| size | 0.20 |
| roast | 0.20 |

Skor 0–100 → Quality Profile: `High` · `Medium` · `Low`.

Pemetaan ke Indicative Grade (default, dapat dikonfigurasi):

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

```
IF roast = Green
THEN tidak ada rekomendasi seduh normal; roasting diperlukan
```

---

## 13. Evaluation

**Detection:** Precision, Recall, mAP50, mAP50-95, IoU.
Fokus: akurasi deteksi, biji overlap, false positive, biji terlewat.

**Classification:** Accuracy, Precision, Recall, Macro F1, Confusion Matrix, per-class.
Fokus roast: Light↔Medium, Medium↔Dark.
Fokus defect: 6 kelas.

**Batch-level:** Bean Count Error, Defect Count Error, Defect Rate Error, Species/Roast Agreement, Quality Score Error, Recommendation & Recipe Retrieval Consistency.

**Recommendation:** cek kecocokan metode, asal parameter resep, keberadaan source, dan status `uncertain`.

---

## 14. Optimization & Target

```
Model terbaik → Export mobile → INT8 quantization
→ Representative dataset → Benchmark
```

Bandingkan: accuracy, F1/mAP, latency, RAM, ukuran model.

| Target | Nilai | Catatan |
|---|---|---|
| Ukuran total model | ≤ ~4 MB | **Perlu dikaji ulang** (4 model INT8 berisiko melebihi) |
| Latensi inference | < ~1 detik | |
| RAM | < ~120 MB | |

---

## 15. Result Object

```json
{
  "species": "Arabica",
  "roast": "Medium",
  "roast_confidence": 0.91,
  "roast_distribution": { "Light": 3, "Medium": 19, "Dark": 2 },
  "visible_beans": 24,
  "defects": {
    "Healthy": 20, "Broken": 2, "Insect Damage": 1,
    "Quaker": 1, "Scorched": 0, "Foreign Matter": 0
  },
  "defect_rate": 0.167,
  "shape_uniformity": 0.86,
  "size_uniformity": 0.88,
  "roast_uniformity": 0.9,
  "status": "OK",
  "quality_score": 82,
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

Catatan: `status` (`OK` / `Uncertain`) diturunkan dari `roast_confidence` vs ambang, bukan kelas paksa.

---

## 16. Aturan Non-Negotiable (ringkas)

1. Jangan merge dataset buta-buta; jaga provenance & versi.
2. Test set tidak untuk training/kalibrasi.
3. Split sebelum augmentation.
4. Jangan map label berbeda tanpa justifikasi (`burnt`≠`scorched`, Grade A≠healthy, NG≠final).
5. YOLOv8n = arsitektur utama (Detection untuk lokalisasi, Classification untuk species/roast/defect).
6. Shape pakai CV, bukan ML.
7. Quality Score = rule engine; rekomendasi = KB + rules.
8. Grind/air/suhu/waktu berasal dari resep terpilih, bukan prediksi ML.
9. Green bean tanpa rekomendasi seduh normal.
10. Timer seduh interaktif out of scope.
11. Setiap eksperimen reproducible dari `experiment_registry.csv`.
12. Evaluasi detection & classification terpisah, plus batch-level & recommendation.
13. Rekomendasi utama = species + quality profile; roast/defect sebagai konteks.

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

Catatan: lampiran ini jembatan sementara. Saat `dataset_registry.csv` dibuat, URL mentah menjadi sumber kebenaran tunggal dan lampiran ini cukup merujuk padanya.

---

## Lampiran B — Sumber Brewing

| ID | Nama | URL |
|---|---|---|
| BR001 | andmos/Coffee | https://github.com/andmos/Coffee |
| BR002 | BrewSpec | https://brewspec.coffee/ |
| BR003 | Coffee Master Recipes | https://coffeemaster.app/recipes |
| BR004 | afrians19/coffee-app | https://github.com/afrians19/coffee-app |
