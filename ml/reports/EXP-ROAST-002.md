# EXP-ROAST-002 — Model Roast (YOLOv8n-cls) di atas DS003 Ter-dedup

Status: **DONE** (training + evaluasi + export INT8 selesai di Kaggle)
Tanggal: 2026-10-13
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

### 4.1 Jumlah grup per kelas per split

Jumlah `group_id` unik (bukan jumlah gambar) per kelas per split:

| Kelas | train | val | test | total |
|---|---|---|---|---|
| Dark | 181 | 44 | 44 | 269 |
| Green | 196 | 45 | 45 | 286 |
| Light | 198 | 45 | 45 | 288 |
| Medium | 201 | 45 | 45 | 291 |
| **Total** | **776** | **179** | **179** | **1134** |

Grup berisi >1 gambar hanya ada di split train (42 grup, 102 gambar):

| Kelas | Grup >1 (train) | Gambar dalam grup >1 (train) |
|---|---|---|
| Dark | 14 | 40 |
| Green | 11 | 24 |
| Light | 10 | 22 |
| Medium | 7 | 16 |
| **Total** | **42** | **102** |

Catatan penting: `val` dan `test` **100% singleton** — tidak ada satu pun grup multi-gambar di
keduanya. Ini bukan hasil desain, melainkan efek samping greedy splitter (baris 59–69
`make_split.py`): tiap grup ditempatkan ke split dengan rasio-terisi terkecil, dan karena
target train 4,67× lebih besar (`0.70` vs `0.15`), rasio train selalu paling rendah di awal
sehingga semua grup besar terserap ke train.

Konsekuensinya dua arah dan keduanya harus jujur dicatat:

- **Bagus:** tidak ada grup near-duplicate yang bocor ke val/test.
- **Kurang bagus:** kemampuan grup-aware split untuk menjaga val/test dari kebocoran
  **tidak benar-benar teruji**, karena val/test tidak pernah menerima grup besar. Sisa
  kemiripan lintas split (bagian 6) sepenuhnya berasal dari pasangan **antar-grup** yang
  similarity-nya di bawah ambang 0.95.

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

Konfigurasi (dari `args.yaml` dan `run_meta.json`):

| Parameter | Nilai |
|---|---|
| Model | YOLOv8n-cls, pretrained |
| imgsz / batch / seed | 224 / 32 / 42 |
| Epoch maksimum | 100 |
| Early stopping | patience 10, monitor `val` |
| Augmentasi | fliplr 0.5, flipud 0.0, degrees 10, translate 0.1, scale 0.1, **hsv_h 0, hsv_s 0**, hsv_v 0.2 |
| Kalibrasi INT8 | 200 gambar, **hanya dari split train** |

Augmentasi warna sengaja dinolkan pada hue dan saturasi (aturan keras #5: warna = fitur
roast). Hanya kecerahan (`hsv_v`) yang diberi ruang 0.2.

Jalannya training:

- Berhenti di **epoch 17** dari 100 (early stopping; tidak ada perbaikan setelah epoch 7).
- **Best epoch = 7**, tersimpan sebagai `best.pt`.
- `val/top1` selama training berfluktuasi 0.849 (epoch 3) hingga 1.000 (epoch 7, 10, 15).
  Fluktuasi ini wajar: val hanya 179 gambar, sehingga 1–2 gambar yang berpindah sudah
  menggeser akurasi ~0.005–0.01.

Metrik akhir pada `best.pt`:

| Metrik | Val (n=179) | Test (n=179) |
|---|---|---|
| Accuracy (top-1) | **1.0000** | **1.0000** |
| Top-5 accuracy | 1.0000 | 1.0000 |
| Macro F1 | **1.0000** | **1.0000** |

Laporan per kelas (test):

| Kelas | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| Dark | 1.0000 | 1.0000 | 1.0000 | 44 |
| Green | 1.0000 | 1.0000 | 1.0000 | 45 |
| Light | 1.0000 | 1.0000 | 1.0000 | 45 |
| Medium | 1.0000 | 1.0000 | 1.0000 | 45 |

Confusion matrix (baris = label benar, kolom = prediksi; urutan `Dark, Green, Light, Medium`):

```
[[44  0  0  0]
 [ 0 45  0  0]
 [ 0  0 45  0]
 [ 0  0  0 45]]
```

Ukuran model: 1.440.004 parameter, 3,3 GFLOPs. `best.pt` = 2.969.800 byte (2,83 MiB).

## 8. Hasil INT8 dan selisih

Export ke TFLite INT8 memakai kalibrasi dari `ml/data/calib/` (200 gambar, seluruhnya dari
split train — aturan keras #11 terpenuhi). Notebook memverifikasi ulang setiap gambar
kalibrasi ∈ split train sebelum export.

| Metrik | Float | INT8 | Selisih |
|---|---|---|---|
| Test accuracy | 1.0000 | **1.0000** | **+0.0000** |
| Test macro F1 | 1.0000 | **1.0000** | **+0.0000** |

Ukuran file:

| Artefak | Byte | MiB |
|---|---|---|
| `roast_exp002_best.pt` | 2.969.800 | 2,83 |
| `roast_exp002_int8.tflite` | 1.584.934 | 1,51 |

Rasio kompresi: **53,4%** dari `best.pt`. Angka 1,51 MiB masih di bawah target ukuran model
(≤ ~4 MB, lihat `AGENTS.md` §7 — target ini masih perlu dikaji ulang, jadi ini sekadar catatan).

Catatan kejujuran soal selisih: **selisih +0.0000 bukan bukti kuantisasi "gratis"**. Karena
float sudah 1.0000 di test, tidak ada ruang turun yang bisa terdeteksi. Kalau float 0.97,
selisih baru akan informatif. Jadi yang benar-benar terbukti di sini hanyalah: INT8 **tidak
merusak** hasil, bukan bahwa INT8 tidak akan pernah menurunkan akurasi.

## 9. Fokus Light↔Medium dan Medium↔Dark

Kedua batas yang paling sulit secara visual (dan paling penting untuk roast):

| Kesalahan | Val | Test |
|---|---|---|
| Light → Medium | 0 | 0 |
| Medium → Light | 0 | 0 |
| Medium → Dark | 0 | 0 |
| Dark → Medium | 0 | 0 |

Nol kesalahan di kedua arah, pada float maupun INT8.

**Tapi ini tidak boleh dibaca sebagai "masalah batas Medium sudah selesai".** Yang diuji
baru foto studio DS003. Justru karena batas Medium↔Dark adalah yang paling mudah bocor
(ingat: pada ambang dedup 0.94 saja sudah muncul pasangan lintas kelas Dark↔Medium di
bagian 3), nol kesalahan di sini lebih mencerminkan kemudahan dataset daripada kualitas
model. Uji yang menentukan adalah foto nyata dari HP pengguna (lihat §10).

## 10. Peringatan kejujuran (wajib dibaca sebelum memakai angka ini)

> **Skor 1.0 sempurna di seluruh metrik BUKAN kabar baik — itu tanda dataset sudah "habis".**
>
> 1. **Batas 0.95 belum menghilangkan kemiripan lintas split.** Masih ada **198 pasangan
>    train→val** dengan similarity >0.93 (maksimum 0.9500), **208 pasangan train→test** >0.93,
>    dan 28 pasangan val→test >0.93 (bagian 6). Dedup MD5 + embedding belum menghapus
>    redundansi di level "foto studio".
> 2. **Akar masalahnya DS003 sendiri.** Semua biji difoto di studio seragam — latar putih,
>    pencahayaan, dan sudut sama. Model tidak perlu belajar membedakan roast; ia cukup
>    mengenali kondisi pengambilan gambar.
> 3. **Val/test 100% singleton** (bagian 4.1), jadi grup-aware split tidak pernah benar-benar
>    diuji pada val/test.
> 4. **Selisih INT8 +0.0000 tidak informatif** karena float sudah jenuh di 1.0 (bagian 8).
>
> **Yang benar-benar terbukti dari EXP-ROAST-002:**
> - Pipeline sehat dan reproducible (split dari `split.csv`, kalibrasi train-only, seed 42).
> - INT8 tidak merusak hasil.
> - Model muat dengan nyaman (1,44 juta parameter; 1,51 MiB INT8).
>
> **Yang BELUM terbukti:** ketahanan model pada foto asli pengguna. Angka 1.0 di laporan ini
> **tidak boleh** diklaim sebagai performa dunia nyata.
>
> **Langkah yang diperlukan sebelum klaim apa pun:** uji pada 20–30 foto biji nyata dari HP
> (cahaya ruangan, latar bebas). Itu satu-satunya bukti yang bermakna. Jika akurasi jatuh
> jauh, penyebabnya bukan model, melainkan domain DS003 yang terlalu sempit — dan solusinya
> adalah data tambahan, bukan hyperparameter.

