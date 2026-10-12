# EXP-ROAST-002 — Model Roast (YOLOv8n-cls) di atas DS003 Ter-dedup

Status: **PENDING** (training berjalan di Kaggle)
Tanggal: 2026-10-12
Dataset: DS003 (`gpiosenka/coffee-bean-dataset-resized-224-x-224`) setelah dedup → `ahmadkevinmalikz/roastmate-ds003-dedup`
Notebook: `ml/notebooks/roast_classification_exp002.ipynb`
Split (sumber kebenaran): `ml/registries/split.csv`, SHA256 `b75d9a16cae9d4c394d1c66117612496e1046504cba714d80ab316f5a33ca92c`

---

## 1. Mengapa EXP-ROAST-001 dibatalkan

`EXP-ROAST-001` berstatus **INVALID_LEAKAGE**.

Audit (`ml/data/audit_ds003_report.txt`) menemukan seluruh isi folder `test/` DS003 adalah
**duplikat persis (MD5 identik)** dari gambar di `train/`. Karena itu:

- 400 dari 400 gambar `test/` punya kembaran byte-identik di `train/`.
- Skor `val` 1.0 dan `test` 1.0 pada EXP-ROAST-001 bukan hasil generalisasi, melainkan
  artefak kebocoran: model hanya perlu mengingat gambar latih.
- Angka tersebut **tidak boleh dipakai** sebagai klaim performa model roast.

Baris `EXP-ROAST-001` tetap ada di `ml/registries/experiment_registry.csv` (tidak dihapus),
hanya statusnya diubah. Artefak `ml/models/best.pt` dan `ml/models/best_int8.tflite`
disimpan sebagai referensi saja, tidak dipakai.

## 2. Dedup lapis 1 — duplikat persis (MD5)

Skrip: `ml/scripts/build_manifest.py` → `ml/data/manifest.csv`.

- Total file DS003: **1600** (400 per kelas; `train/` 300 + `test/` 100 per kelas).
- Grup MD5: **1194**.
- Duplikat persis yang dibuang: **406 file**.
- Aturan pemilihan representan: prioritaskan file dari `train/`, lalu nama file terkecil
  secara leksikografis (tercatat di dalam skrip).
- Hasil: **1194 gambar unik**, seluruhnya berasal dari `train/` (0 dari `test/`).

Jumlah unik per kelas:

| Kelas | Unik (keep=1) | Total awal |
|---|---|---|
| Dark | 295 | 400 |
| Green | 299 | 400 |
| Light | 300 | 400 |
| Medium | 300 | 400 |
| **Total** | **1194** | **1600** |

Ketidakseimbangan kelas ini wajar: jumlah duplikat berbeda antar kelas
(Dark kehilangan 105, Green 101, Light 100, Medium 100).

## 3. Dedup lapis 2 — near-duplicate berbasis embedding

Skrip: `ml/scripts/embed_dedup.py`. Backbone **ResNet-18 pretrained ImageNet, tanpa
fine-tuning**; fitur 512-d dari `avgpool`, dinormalisasi L2, kemiripan = cosine similarity.

- Pasangan dievaluasi: 712.221
- Pasangan dengan similarity ≥ 0.95: **62**, dan **0 di antaranya lintas kelas**.

Sebaran lintas kelas per pita similarity (dasar pemilihan ambang):

| Pita | Total pasangan | Satu kelas | Lintas kelas |
|---|---|---|---|
| ≥ 0.95 | 62 | 62 | **0** |
| [0.94, 0.95) | 350 | 346 | 4 |
| [0.93, 0.94) | 1380 | 1276 | 104 |
| [0.92, 0.93) | 3745 | 3301 | 444 |
| [0.90, 0.92) | 21509 | 16767 | 4742 |

**Ambang final: 0.95.** Alasan:

1. Seluruh pasangan ≥ 0.95 sudah diperiksa visual (montase 4 pita) dan memang foto yang
   sama / pengambilan ulang dari biji yang sama.
2. Begitu ambang diturunkan ke 0.94, muncul pasangan **lintas kelas** (Dark↔Medium) yang
   secara visual mirip. Menyatukan grup lintas kelas berarti mencampur batas
   Medium↔Dark — justru batas yang paling penting untuk model roast.
3. Karena itu 0.95 adalah patahan alami: ambang tertinggi yang masih bebas konflik label.

Efek penggabungan pada 0.95 (union-find):

- 1194 gambar → **1134 grup**.
- 42 grup berisi >1 gambar, mencakup **102 gambar**.
- Sebaran ukuran grup: 1 gambar ×1092, 2 ×35, 3 ×5, 4 ×1, 13 ×1.
- Semua grup berukuran >1 berada dalam **satu kelas** (0 grup lintas kelas).
- Tidak ada gambar yang dihapus pada tahap ini — hanya ditandai `group_id`.
- Grup terbesar (13 gambar, semua Dark) terbentuk karena *chaining* (A~B, B~C, …).
  Efeknya konservatif: gambar-gambar itu tetap satu split, sehingga tidak ada kebocoran.
  Pasangan terlemah di grup itu 0.8945, jadi sebagian pasangan memang tidak identik;
  ini dicatat sebagai keterbatasan dan bahan perbaikan berikutnya.

## 4. Split grup-aware dan stratified

Skrip: `ml/scripts/make_split.py` → `ml/registries/split.csv`.
Unit split adalah `group_id` (bukan file), rasio 70/15/15, seed 42.

| Kelas | train | val | test | total |
|---|---|---|---|---|
| Dark | 207 | 44 | 44 | 295 |
| Green | 209 | 45 | 45 | 299 |
| Light | 210 | 45 | 45 | 300 |
| Medium | 210 | 45 | 45 | 300 |
| **Total** | **836** | **179** | **179** | **1194** |

Verifikasi otomatis (skrip gagal bila tidak lolos):

- (a) tidak ada `group_id` yang muncul di lebih dari satu split — **lolos**
- (b) setiap kelas hadir di ketiga split — **lolos**
- (c) tidak ada `path` yang muncul dua kali — **lolos**

## 5. Materialisasi dataset dan kalibrasi INT8

Skrip: `ml/scripts/materialize.py`.

- Dataset terstruktur: `ml/data/ds003_dedup/{train,val,test}/{kelas}/`.
- Kalibrasi: `ml/data/calib/` berisi **200 gambar unik, semuanya dari split train**
  (0 dari val, 0 dari test). Bukti asal: `ml/data/calib_manifest.csv`.

Catatan teknis penting: Ultralytics `check_cls_dataset()` untuk kalibrasi klasifikasi
memakai split `val` dari argumen `data`, dan bila folder `train/` tidak ada ia akan
**membuat split acak 80/20 sendiri**. Karena itu `ml/data/calib/` dibuat terstruktur
(`calib/train/` dan `calib/val/`, isi identik, keduanya dari split train), dan notebook
memverifikasi setiap gambar kalibrasi ∈ split train sebelum export.

## 6. Diagnostik sisa near-duplicate lintas split

Dedup 0.95 menjamin tidak ada grup yang melintasi split, tetapi **bukan** berarti tidak ada
kemiripan sisa. Kemiripan maksimum tiap gambar ke split lain (embedding ResNet-18):

| Arah | maks | rata-rata | p95 | min | pasangan >0.93 | >0.94 |
|---|---|---|---|---|---|---|
| train → val | 0.9500 | 0.9192 | 0.9414 | 0.8430 | 198 | 54 |
| train → test | 0.9499 | 0.9187 | 0.9407 | 0.8606 | 208 | 48 |
| val → test | 0.9499 | 0.9164 | 0.9397 | 0.8174 | 28 | 8 |

Artinya: masih ada ratusan gambar val/test yang punya "tetangga dekat" di train
(similarity 0.93–0.95, di bawah ambang dedup). Ini karena dataset sumber memang sangat
redundan, bukan karena split salah. Konsekuensinya harus jujur dicatat:

> Skor val/test yang sangat tinggi pada dataset ini **tidak boleh** dibaca sebagai
> performa pada foto pengguna nyata. Dataset DS003 punya latar, pencahayaan, dan
> sudut pengambilan yang seragam, sehingga jauh lebih mudah daripada foto asli.

Keterbatasan lain: grup 13 gambar (bagian 3) terbentuk karena *chaining*, sehingga
sebagian anggotanya sebenarnya hanya mirip (~0.89), bukan kembar. Efeknya konservatif
(gambar tetap satu split), tetapi ukuran grup tidak akurat dan perlu diperbaiki nanti
(mis. complete-linkage atau ambang bertingkat).

## 7. Hasil training (float)

PENDING

## 8. Hasil INT8 dan selisih

PENDING

## 9. Fokus Light↔Medium dan Medium↔Dark

PENDING
