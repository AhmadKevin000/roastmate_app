# EXT-ROAST-002-DS006 — Evaluasi Eksternal Model Roast pada DS006

Status: **SELESAI**
Tanggal: 2026-10-13
Model: `ml/models/roast_exp002_best.pt` (YOLOv8n-cls; kelas `Dark`, `Green`, `Light`, `Medium`)
Data uji: DS006 "Kopi Robusta dan Arabika" (Roboflow Universe), subset **Robusta** saja
Kode: `ml/scripts/ds006_manifest.py`, `ds006_internal_dup.py`, `ds006_leakage.py`, `ds006_eval_set.py`, `predict_photos.py`

---

## 0. Kesimpulan utama

**Akurasi pada 283 foto Robusta: 33,92% (96/283).** Bandingkan dengan 100% pada test DS003.

Tiga hal yang harus dibaca bersamaan:

1. **Domain shift besar.** Turun 66 poin persentase. Ini bukti langsung bahwa skor 1.0 di DS003 tidak mewakili kemampuan membaca roast pada foto dari sumber lain.
2. **DS006 bukan dataset eksternal yang independen.** Bagian **Arabica**-nya (300 dari 583 foto sumber) **terbukti adalah DS003 itu sendiri** — gambar yang dipakai melatih model ini. Karena itu Arabica dibuang total dan evaluasi hanya memakai Robusta.
3. **Prediksi `Green` muncul 69 kali (24,4%)** padahal DS006 tidak punya label Green sama sekali. Model membawa bias DS003 (yang punya Green) ke domain baru. Setiap prediksi Green dihitung salah.

Angka 33,92% **tidak boleh** dibaca sebagai "model ini buruk 33%". Sebagian besar kesalahan terkonsentrasi di batas yang memang ambigu (lihat §7 dan §9).

---

## 1. Sumber dan deskripsi DS006

Dari `ml/data/ds006/README.dataset.txt` dan `README.roboflow.txt`:

- Nama: **Kopi Robusta dan Arabika — v1**, diekspor dari roboflow.com pada **23 April 2025**.
- Sumber: `https://universe.roboflow.com/tugas-akhir-8wmr1/kopi-robusta-dan-arabika`
- Lisensi: **CC BY 4.0**.
- Jumlah gambar yang dinyatakan README: **1389**.
- Format anotasi: **folder** (satu folder per kelas).
- Pra-pemrosesan per gambar: auto-orientation (strip EXIF), **resize 256×256 (stretch)**.
- Augmentasi (dinyatakan): **3 versi per gambar sumber** — flip horizontal (probabilitas 50%) dan rotasi acak −15°…+15°.

Struktur: `ml/data/ds006/{train,valid,test}/<Species> <Roast>/`, contoh `Arabica Dark`, `Robusta Light`.

Pemetaan label **eksplisit** (tidak ada penggabungan dengan label DS003):

| Dari nama folder | Menjadi |
|---|---|
| token pertama | `species_label` ∈ {`Arabica`, `Robusta`} |
| token terakhir | `roast_label` ∈ {`Dark`, `Light`, `Medium`} |

DS006 tidak punya kelas `Green`. Tidak ada kelas DS006 yang dipetakan ke Green.

## 2. Jumlah gambar (sebelum pembersihan)

| Split | Arabica Dark | Arabica Light | Arabica Medium | Robusta Dark | Robusta Light | Robusta Medium | Total |
|---|---|---|---|---|---|---|---|
| train | 185 | 209 | 242 | 206 | 207 | 164 | 1213 |
| valid | 28 | 21 | 15 | 18 | 14 | 20 | 116 |
| test | 10 | 9 | 4 | 12 | 8 | 17 | 60 |
| **Total** | **223** | **239** | **261** | **236** | **229** | **201** | **1389** |

Per roast: Dark 459, Light 468, Medium 462. Per species: Arabica 723, Robusta 666.

## 3. Langkah 2 — duplikat internal DS006

### 3.1 Mengapa bukan union-find 0.95

Pendekatan embedding + union-find (seperti `embed_dedup.py` di DS003) **gagal di DS006**. Pada ambang 0.95, union-find membentuk satu grup berisi **596 gambar** yang isinya tercampur:

```
roast   : Dark 219, Light 188, Medium 189   <-- 3 kelas berbeda dalam 1 grup
species : Robusta 596
split   : train 521, valid 44, test 31
```

Penyebabnya **chaining** (A~B, B~C, …). Di DS006 ada **488 pasangan similarity ≥0.95 yang lintas roast** (contoh: Light↔Medium Robusta 0,9754) dan **0 pasangan lintas species**. Jadi ambang 0.95 tidak memisahkan tingkat roast di DS006 sama sekali — berbeda dengan DS003, yang pada 0.95 menghasilkan 0 pasangan lintas kelas.

Karena itu grup duplikat internal ditentukan oleh **provenance augmentasi Roboflow** yang eksak: nama file `<basis_sumber>.rf.<hash>.jpg`, basis = nama file tanpa pola `.rf.<hash>`. Ini deterministik dan tidak bisa chaining.

### 3.2 Hasil

| Ukuran | Jumlah |
|---|---|
| Gambar total | 1389 |
| **Basis sumber unik** | **583** |
| Basis dengan 3 versi | 399 |
| Basis dengan 2 versi | 8 |
| Basis dengan 1 versi | 176 |
| MD5 identik (pasangan) | 19 (semuanya train–train) |
| MD5 unik | 1370 |

Distribusi versi per split: **semua** basis multi-versi berada di `train` (`{train:3}` ×399, `{train:2}` ×8). Artinya:

- `train` = 1213 gambar, hanya **407 foto sumber**.
- `valid` = 116 gambar = **116 sumber unik** (tanpa augmentasi).
- `test` = 60 gambar = **60 sumber unik** (tanpa augmentasi).

Gambar yang berada dalam grup multi-versi: **1213/1389 = 87,3%** — melewati ambang henti 30%.

### 3.3 Pengecualian aturan 30% (disetujui user)

> Aturan: "jika lebih dari 30% gambar DS006 masuk grup duplikat internal, HENTIKAN."
>
> **Kondisi terpicu (87,3%), dan user menyetujui pengecualian** dengan alasan yang dicatat di sini:
> duplikasi itu **100% berasal dari augmentasi Roboflow di split `train`**, dan `train` **tidak dipakai untuk evaluasi**. `valid` dan `test` (176 gambar) seluruhnya singleton — nol salinan augmentasi. Jadi duplikasi internal tidak mengontaminasi set evaluasi.
>
> Keputusan user: **dedup berdasarkan basis nama file → 583 gambar** (satu representan per foto sumber). Aturan representan: prioritas split `test` > `valid` > `train`, lalu nama file terkecil secara leksikografis. Diverifikasi setiap basis punya tepat satu representan.

Hasil dedup: **583 gambar** — train 407, valid 116, test 60; per roast Dark 200, Light 191, Medium 192; per species Arabica 300, Robusta 283.

## 4. Langkah 3 — kebocoran DS006 terhadap DS003

Dibandingkan dengan **seluruh 1600 gambar DS003** (train/ dan test/), dua lapis.

### 4.1 MD5

**0 gambar** DS006 yang punya kembar byte-identik di DS003.

### 4.2 Embedding (ResNet-18 ImageNet, tanpa fine-tune, cosine similarity)

Similarity maksimum tiap gambar DS006 ke gambar DS003 terdekat:

| Statistik | Nilai |
|---|---|
| maksimum | 0,9889 |
| rata-rata | 0,8357 |
| minimum | 0,5437 |

| Ambang | Gambar DS006 dengan tetangga DS003 ≥ ambang |
|---|---|
| ≥ 0,99 | 0 |
| ≥ 0,98 | 55 |
| ≥ 0,97 | 148 |
| ≥ 0,96 | 182 |
| ≥ 0,95 | **209** |
| ≥ 0,93 | 260 |
| ≥ 0,90 | 293 |

Pola kesesuaian label sangat tajam (bimodal):

| Pita similarity | n | Label DS006 = label DS003 |
|---|---|---|
| [0,98, 1,00) | 55 | **100%** |
| [0,95, 0,98) | 154 | **100%** |
| [0,93, 0,95) | 51 | **100%** |
| < 0,90 | 290 | 7,2% |

### 4.3 🔴 Temuan kritis: bagian Arabica DS006 **adalah** DS003

Diuji lewat nama file. Roboflow menyanitasi nama asli: `dark (40).png` → `dark-40-_png.rf.<hash>.jpg`. Hasil pencocokan:

| Bukti | Hasil |
|---|---|
| Basis DS006 yang namanya cocok dengan file DS003 | **300 / 583 (51,5%)** |
| Semuanya Arabica | ya — Dark 100, Light 100, Medium 100 |
| Rentang nomor | N = **1–100**, 100 unik per kelas |
| Kesesuaian label | **100%** |

Bukti pendukung dari embedding:

| Kelompok | n | sim maks ke DS003 | rata-rata | ≥ 0,95 |
|---|---|---|---|---|
| **Arabica** | 300 | 0,9889 | **0,9595** | **209** |
| **Robusta** | 283 | **0,7849** | 0,7045 | **0** |

Kesimpulan: **seluruh bagian Arabica DS006 adalah DS003** (data latih EXP-ROAST-002), hanya di-upload ulang ke Roboflow lalu diproses (resize stretch + augmentasi). **DS006 bukan dataset eksternal yang independen.**

Catatan penting soal sensitivitas metode: aturan deteksi (MD5 atau cosine >0,95) hanya menangkap **209** gambar, sedangkan bukti provenance menemukan **300**. Sebabnya, pra-pemrosesan Roboflow menurunkan kemiripan ke 0,93–0,99 — **di bawah 0,95 untuk 91 gambar**. Jadi ambang 0,95 **kurang sensitif** dibanding pencocokan nama file.

### 4.4 Kondisi henti terpicu

Bocor (MD5 atau similarity ≥0,95): **209/583 = 35,8%** — melewati ambang henti 20%. Evaluasi **dihentikan** dan user memutuskan:

> **Evaluasi hanya pada bagian Robusta (283 sumber).** Arabica dibuang total karena terbukti bersumber sama dengan DS003. Robusta bersih dari kebocoran (similarity maksimum ke DS003 hanya 0,7849; nol pasangan ≥0,93).

Catatan kecil: satu gambar DS003, `train/Green/green (36).png`, menjadi tetangga terdekat bagi 207 gambar Robusta — tetapi pada similarity rendah (0,618–0,785). Ini bukan kebocoran; hanya gambar DS003 yang "generik" dan mendominasi tetangga terdekat. Dampaknya nol terhadap evaluasi (Robusta tetap jauh di bawah ambang).

## 5. Set evaluasi final

`ml/data/ds006/manifest_clean.csv` — **283 gambar Robusta**:

| Roast | Jumlah |
|---|---|
| Dark | 100 |
| Light | 91 |
| Medium | 92 |
| **Total** | **283** |

| Split asal DS006 | Jumlah |
|---|---|
| train | 194 |
| valid | 52 |
| test | 37 |

Per species: Robusta 283 (100%).

## 6. Hasil evaluasi (Langkah 4)

Model: `ml/models/roast_exp002_best.pt`. Daftar file dikirim eksplisit ke `predict()` (bukan folder). Kelas dipetakan lewat `model.names` = `{0:'Dark', 1:'Green', 2:'Light', 3:'Medium'}`. Label evaluasi hanya Dark/Light/Medium, sehingga **prediksi Green selalu dihitung salah**.

**Akurasi keseluruhan (3 kelas): 96/283 = 33,92%.**

**Prediksi `Green` muncul 69 kali (24,4%)** — kelas yang tidak ada di DS006. Distribusinya: dari 100 Dark → 8, dari 91 Light → 49, dari 92 Medium → 12.

### 6.1 Confusion matrix (baris = label DS006, kolom = prediksi model)

| true \ pred | Dark | Green | Light | Medium | total |
|---|---|---|---|---|---|
| **Dark** | 51 | 8 | 2 | 39 | 100 |
| **Light** | 19 | 49 | 10 | 13 | 91 |
| **Medium** | 4 | 12 | 41 | 35 | 92 |
| total | 74 | 69 | 53 | 87 | 283 |

### 6.2 Akurasi dan F1 per kelas

| Kelas | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| Dark | 0,6892 | 0,5100 | **0,5862** | 100 |
| Light | 0,1887 | 0,1099 | **0,1389** | 91 |
| Medium | 0,4023 | 0,3804 | **0,3911** | 92 |

- **Macro F1 (3 kelas) = 0,3721.**
- Macro F1 (4 kelas, Green support 0) = 0,2790.
- Akurasi per split asal: train 66/194 = 34,0%; valid 18/52 = 34,6%; test 12/37 = 32,4% (konsisten).
- Confidence: min 0,281, maks 0,967, rata-rata 0,564.

### 6.3 Pasangan kesalahan terbesar

| Kesalahan | Jumlah |
|---|---|
| Light → Green | 49 |
| **Medium → Light** | **41** |
| **Dark → Medium** | **39** |
| Light → Dark | 19 |
| Light → Medium | 13 |
| Medium → Green | 12 |
| Dark → Green | 8 |
| Medium → Dark | 4 |
| Dark → Light | 2 |

Fokus dua batas yang diminta:

- **Light ↔ Medium**: Light→Medium 13, Medium→Light 41 → total **54 kesalahan**.
- **Medium ↔ Dark**: Medium→Dark 4, Dark→Medium 39 → total **43 kesalahan**.

Ini dua pasangan kesalahan terbesar setelah Light→Green. Perhatikan asimetri: Medium→Light (41) jauh lebih besar daripada Light→Medium (13), dan Dark→Medium (39) jauh lebih besar daripada Medium→Dark (4). Model cenderung **"mencerahkan"** prediksinya di domain Robusta.

### 6.4 Keterbatasan label di dalam Robusta

Di dalam 283 gambar Robusta, ada **86 pasangan lintas roast dengan similarity ≥0,95** (Light–Medium 56, Dark–Medium 25, Dark–Light 5); total pasangan ≥0,95 = 785, ≥0,93 = 3642.

Ini **tidak dibuang**, sesuai keputusan user, dan dicatat sebagai **keterbatasan label**: sebagian batas Dark/Light/Medium pada Robusta memang ambigu secara visual, bahkan bagi embedding ImageNet. Jadi sebagian kesalahan model di §6.3 mencerminkan ambiguitas label, bukan semata kesalahan model.

## 7. Perbandingan dengan DS003 — domain shift

| | DS003 (test) | DS006 Robusta |
|---|---|---|
| Akurasi | **1,0000** | **0,3392** |
| Macro F1 | **1,0000** | **0,3721** |
| Selisih akurasi | — | **−0,6608** |

**Selisih 66 poin persentase ini menunjukkan domain shift.** DS003 difoto di studio dengan latar, pencahayaan, dan sudut seragam; DS006 Robusta berasal dari sumber, kamera, dan latar berbeda. Model yang menghafal kondisi pengambilan gambar DS003 tidak otomatis membaca tingkat roast pada domain baru.

Yang penting: **angka DS003 (1,0) dan DS006 (0,3392) tidak setara maknanya.** DS003 sudah jenuh dan tidak mengukur generalisasi (lihat `ml/reports/EXP-ROAST-002.md` §10). DS006 Robusta adalah pengukuran yang lebih jujur, meskipun tetap bukan foto pengguna nyata.

## 8. Keterbatasan

1. **Label DS006 berasal dari sumber lain** (Roboflow, pengguna `tugas-akhir-8wmr1`), bukan hasil anotasi tim. **Metode pelabelan tidak diketahui** — tidak ada dokumentasi kriteria Dark/Light/Medium yang dipakai.
2. **Latar, kamera, dan pencahayaan berbeda** dari DS003; bukan foto pengguna nyata dari HP. Domain tetap "foto terkurasi", bukan kondisi lapangan.
3. **86 pasangan lintas roast ≥0,95 di dalam Robusta** — sebagian batas label ambigu secara visual (§6.4).
4. **Kelas Green tidak ada di DS006**, sementara model punya kelas Green. 69 prediksi Green (24,4%) dihitung salah; ini mengukur bias kelas dari DS003, bukan kesalahan "murni" pada 3 kelas.
5. **Ambang 0,95 kurang sensitif** untuk mendeteksi kebocoran pada DS006 (§4.3): pencocokan provenance menemukan 300 gambar bocor, ambang similarity hanya 209.
6. **Split DS006 tidak dipakai** sebagai pembeda; evaluasi memakai seluruh 283 Robusta lintas train/valid/test DS006 (akurasi konsisten di ketiganya, jadi tidak ada indikasi masalah).
7. `green (36).png` DS003 mendominasi tetangga terdekat Robusta pada similarity rendah (§4.4) — indikasi embedding ResNet-18 punya baseline tinggi di domain ini, sehingga ambang absolut perlu hati-hati.

## 9. Kesimpulan

- Pada domain berbeda (Robusta, sumber lain), akurasi model roast turun dari 1,0 (DS003) ke **0,3392**, macro F1 0,3721. Ini **domain shift nyata**.
- **DS006 tidak bisa dipakai sebagai uji eksternal secara keseluruhan**, karena bagian Arabica-nya terbukti sama dengan DS003. Hanya 283 gambar Robusta yang sah sebagai uji eksternal.
- Kegagalan terkonsentrasi di batas Medium↔Light (54) dan Medium↔Dark (43), serta pada bias kelas Green (69). Model cenderung "mencerahkan" prediksi.
- Konsekuensi praktis: **model roast EXP-ROAST-002 belum layak dipakai untuk pengguna nyata tanpa data tambahan** dari domain target. Perbaikan yang paling masuk akal adalah menambah data DS006 Robusta ke proses pelatihan berikutnya (bukan menyesuaikan hyperparameter).

## 10. Reproduksi

```bash
cd pbl_sem5
V=ml/.venv/bin/python

# Langkah 1 — manifest DS006
$V ml/scripts/ds006_manifest.py

# Langkah 2 — duplikat internal (basis nama file) + cross-roast >=0.95
$V ml/scripts/ds006_internal_dup.py

# Langkah 3 — kebocoran vs DS003 (MD5 + embedding)
$V ml/scripts/ds006_leakage.py

# Set evaluasi final (Robusta saja)
$V ml/scripts/ds006_eval_set.py

# Langkah 4 — prediksi
$V ml/scripts/predict_photos.py
```

## 11. Aturan yang dipatuhi

- DS006 **tidak** dipakai untuk training, validasi, maupun kalibrasi INT8 (hanya `predict`).
- `ml/registries/split.csv`, `ml/data/calib/`, dan artefak EXP-ROAST-002 **tidak diubah**.
- `experiment_registry.csv` **tidak ditulis** (menunggu persetujuan user).
- Isi `ml/data/` **tidak di-commit**.
- Foto tidak pernah dikirim ke server; seluruh inference lokal.
- Hasil dilaporkan apa adanya, termasuk pengecualian aturan 30% dan kondisi henti 20%.
