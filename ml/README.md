# Roastmate — ML

Folder kerja untuk melatih model visi Roastmate. Model di-*train* terpisah
(offline / Kaggle), lalu hasilnya diekspor ke TFLite INT8 dan disalin ke
`mobile/assets/models/` untuk inference on-device.

Dokumen acuan: `docs/ARCHITECTURE_ML.md` (pipeline, label mapping, evaluasi).

---

## Struktur

```
ml/
├── README.md
├── registries/
│   ├── dataset_registry.csv       # provenance semua dataset (DS001–DS010)
│   └── experiment_registry.csv    # log tiap run training
├── notebooks/
│   └── roast_classification.ipynb # training model Roast (YOLOv8n-Cls)
├── data/     (gitignored)         # cache dataset lokal
├── runs/     (gitignored)         # output training ultralytics
└── models/   (gitignored)         # .pt / .tflite hasil export
```

`data/`, `runs/`, dan `models/` tidak masuk git — isinya besar (dataset &
bobot model). Yang di-commit hanya kode dan registry.

---

## Urutan model

| # | Model | Tugas | Kelas | Dataset | Status |
|---|---|---|---|---|---|
| 1 | YOLOv8n-Cls | Roast | Green / Light / Medium / Dark | DS003 (+DS006) | 🔜 dikerjakan |
| 2 | YOLOv8n-Cls | Species | Arabica / Robusta | DS001 + DS006 | ⏳ |
| 3 | YOLOv8n-Cls | Defect | 6 kelas | DS004 + DS007 + DS008 | ⏳ |
| 4 | YOLOv8n Detection | Lokalisasi biji | `bean` | DS002 + DS007 + DS008 | ⏳ |

Urutan sengaja: **Roast** (paling mudah) → Species → Defect → Detector.

---

## Alur training

1. Jalankan notebook di `notebooks/` (Kaggle: GPU T4 gratis, kuota ~30 jam/minggu).
2. Notebook menghasilkan `best.pt` + `best_int8.tflite`.
3. Salin artefak ke `ml/models/` dan catat baris baru di
   `registries/experiment_registry.csv`.
4. Salin `.tflite` final ke `mobile/assets/models/`.

---

## Konvensi

- **Split 70/15/15 sebelum augmentasi**; test set tidak untuk training/kalibrasi.
- **Augmentasi roast:** hindari perubahan warna ekstrem (hue/warna = fitur utama).
- Label target training **snake_case**; enum DB/UI **Title Case**
  (lihat `ARCHITECTURE_ML.md` §3).
- Setiap eksperimen punya baris di `experiment_registry.csv` agar reproducible.
- `dataset_registry.csv` = sumber kebenaran tunggal URL dataset (lihat D-09).

---

## Setup lokal (opsional)

Training lokal butuh **Python 3.11/3.12** — versi 3.14 belum didukung PyTorch.

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install ultralytics kagglehub
```
