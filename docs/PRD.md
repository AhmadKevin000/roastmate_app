# ROASTMATE — PRODUCT REQUIREMENTS DOCUMENT (PRD)

Versi: 1.0
Status: Draft
Cakupan: Aplikasi mobile on-device untuk analisis batch biji kopi dari foto.

---

## 1. Ringkasan Produk

Roastmate adalah aplikasi mobile yang menganalisis **satu foto batch biji kopi** dan menghasilkan profil kopi serta rekomendasi seduh.

Yang dihasilkan:

| Output | Sumber |
|---|---|
| Jenis kopi (Arabica / Robusta / Mixed) | Model visi (YOLOv8n-Cls) |
| Tingkat roast (Green / Light / Medium / Dark) | Model visi (YOLOv8n-Cls) |
| Defect per biji (6 kelas) | Model visi (YOLOv8n-Cls) |
| Bentuk & keseragaman batch | OpenCV (bukan ML) |
| Quality Score 0–100 + profile | Rule engine (bukan ML) |
| Rekomendasi metode seduh + parameter awal | Knowledge base + rules (bukan ML) |

Prinsip inti: **ML hanya untuk visual (deteksi + klasifikasi). Quality score dan parameter seduh dihitung oleh rule engine + knowledge base, bukan diprediksi langsung oleh model gambar.**

---

## 2. Masalah & Target

### Masalah
- Penilaian kualitas biji kopi umumnya subjektif, manual, dan butuh pengalaman.
- Petani/roaster/barista pemula sulit menentukan kualitas batch dan resep seduh awal.
- Peralatan grading laboratorium mahal dan tidak praktis untuk penggunaan sehari-hari.

### Target
- Memberi penilaian kualitas batch yang **cepat, konsisten, dan dapat diulang**.
- Memberi **titik awal seduh** yang masuk akal berdasarkan profil kopi.
- Sepenuhnya **on-device** (offline, privat, tanpa upload foto).

### Non-target
- Bukan pengganti sertifikasi laboratorium fisik.
- Bukan alat kontrol roasting otomatis.

---

## 3. Pengguna & Use Case

| Persona | Kebutuhan |
|---|---|
| Petani / produsen | Menilai kualitas batch hasil panen/roasting secara cepat |
| Roaster | Memeriksa konsistensi hasil roasting |
| Barista / penggemar | Menentukan metode & parameter seduh awal |
| Mahasiswa / peneliti | Data grading batch yang dapat diekspor |

Use case utama:
1. Foto batch biji → lihat kualitas + rekomendasi seduh.
2. Lihat riwayat analisis sebelumnya.
3. Lihat katalog metode seduh & panduan langkah.
4. Ekspor hasil analisis ke CSV.

---

## 4. Lingkup Fitur per Tab

Aplikasi memiliki 3 tab utama.

### Tab Beranda
- Sapaan & ringkasan.
- Komposisi jenis biji (Arabica / Robusta / Mixed) dari seluruh riwayat.
- Statistik: total analisis, rata-rata skor.
- Kartu CTA "Scan Batch Baru" → kamera.
- Daftar analisis terakhir (ringkas).

### Tab Analisis
- Riwayat analisis (daftar + filter Semua / Arabica / Robusta / Mixed).
- Setiap item: nama, tanggal, jenis, jumlah biji terlihat, jumlah defect, skor, grade.
- Buka detail inspeksi (hasil analisis lengkap).
- Ekspor CSV.

### Tab Seduh
- Katalog metode seduh.
- Ringkasan tiap metode (rasio, waktu, grind, suhu).
- Buka detail resep (panduan langkah statis).

### Layar pendukung
- Scan Kamera (kamera + overlay deteksi + indikator pencahayaan).
- Detail Inspeksi (hasil analisis lengkap).
- Detail Resep (panduan langkah).

---

## 5. User Flow

```
Beranda
  └─ "Scan Batch Baru"
        └─ Scan Kamera
              ├─ Ambil foto batch
              ├─ Image Quality Check
              ├─ Inference on-device
              └─ Detail Inspeksi (hasil + rekomendasi)
                    ├─ Lihat bukti visual klasifikasi
                    ├─ Lihat rincian komposisi biji
                    └─ Buka resep
                          └─ Detail Resep (panduan langkah statis)

Analisis
  └─ Riwayat → Detail Inspeksi → Ekspor CSV

Seduh
  └─ Katalog Metode → Detail Resep
```

---

## 6. Functional Requirements

### FR-01 Scan Kamera
- Menampilkan pratinjau kamera dengan overlay panduan.
- Indikator kualitas pencahayaan (baik / kurang).
- Kontrol zoom (0.5x / 1x / 2x), galeri, flash.
- Tombol capture (target sentuh ≥ 48×48 dp).
- Catatan: hanya biji yang terlihat pada permukaan foto yang dinilai.

### FR-02 Image Quality Check
- Menolak/memperingatkan bila foto gelap, blur, atau tidak ada biji terdeteksi.
- Tidak melanjutkan inference bila kualitas tidak memadai.

### FR-03 Inference On-Device
- Deteksi biji (YOLOv8n Detection) → crop per biji.
- Klasifikasi species, roast, defect per biji (YOLOv8n-Cls).
- Analisis bentuk per biji (OpenCV).
- Semua proses lokal di perangkat.

### FR-04 Detail Inspeksi
- Skor kualitas optik 0–100 + grade.
- Jumlah biji terdeteksi + defect rate.
- Narasi ringkas hasil.
- Rekomendasi seduh terkalibrasi (metode utama + parameter).
- Metode alternatif.
- Bukti visual klasifikasi (bounding box berlabel + zoom).
- Rincian komposisi **defect** per kelas (jumlah + persentase). Species ditampilkan sebagai satu jenis biji saja.
- Disclaimer: penilaian indikatif, bukan sertifikasi laboratorium.

### FR-05 Riwayat Analisis
- Daftar seluruh analisis tersimpan.
- Filter berdasarkan species.
- Ringkasan: total analisis, rata-rata skor, komposisi jenis.
- Ekspor CSV.

### FR-06 Katalog Metode Seduh
- Daftar metode (mis. V60, French Press, Kopi Tubruk).
- Ringkasan parameter tiap metode.
- Buka detail resep.

### FR-07 Detail Resep
- Ringkasan resep (berat, total air, suhu, grind, total waktu, metode).
- Daftar persiapan & alat.
- **Panduan langkah statis** (bernomor, dengan label target waktu sebagai informasi).
- Tips kalibrasi rasa.
- Tidak ada timer interaktif.

### FR-08 Green Bean Handling
- Bila roast terdeteksi `Green`: tampilkan bahwa roasting diperlukan, dan **tidak** berikan parameter seduh normal.

### FR-09 Confidence & Mixed Batch
- Bila confidence di bawah threshold → tandai `uncertain`.
- Bila distribusi species terlalu dekat → species `Mixed`; bila distribusi roast terlalu dekat → status `uncertain`.
- Tidak memaksakan satu kelas.

---

## 7. Non-Functional Requirements

| Aspek | Target |
|---|---|
| Platform | Android & iOS (Flutter) |
| Mode operasi | On-device, offline (tanpa internet) |
| Latensi inference | < ~1 detik per foto |
| Penggunaan RAM | < ~120 MB |
| Ukuran model total | ≤ ~4 MB (perlu dikaji ulang) |
| Privasi | Foto tidak pernah dikirim ke server |
| Riwayat | Tersimpan lokal (SQLite) |
| Bahasa UI | Indonesia |
| Aksesibilitas | Target sentuh ≥ 48×48 dp, kontras teks ≥ 4.5:1 |

---

## 8. Taksonomi & Definisi

### Species
`Arabica` · `Robusta` · `Mixed`

> `Mixed` menandai batch campuran/ambigu. Status `uncertain` (confidence di bawah ambang) adalah **status tampilan**, bukan nilai species — lihat FR-09.

### Roast
`Green` · `Light` · `Medium` · `Dark`

### Defect (6 kelas final)
`Healthy` · `Broken` · `Insect Damage` · `Quaker` · `Scorched` · `Foreign Matter`

### Quality Profile (kanonik, 3 level)
`High` · `Medium` · `Low`

### Indicative Grade (pemetaan default)
| Quality Profile | Score | Grade |
|---|---|---|
| High | 85–100 | Specialty |
| High | 75–84 | Premium |
| Medium | 60–74 | Standard |
| Low | 40–59 | Below Standard |
| Low | 0–39 | Off Grade |

> Ambang grade adalah parameter sistem awal yang dapat dikonfigurasi.

---

## 9. Out of Scope

- ✗ Timer seduh interaktif (countdown / start-stop / sinkronisasi waktu).
- ✗ Kontrol roasting otomatis.
- ✗ Prediksi ML langsung untuk grind/air/suhu/waktu.
- ✗ Penyesuaian otomatis real-time selama proses seduh.
- ✗ Prediksi kelembapan (moisture).
- ✗ Sertifikasi laboratorium fisik.

> Halaman Detail Resep tetap ada sebagai **panduan langkah statis** dengan label target waktu tekstual — bukan timer aktif.

---

## 10. Acceptance Criteria

| ID | Kriteria |
|---|---|
| AC-01 | Satu foto batch menghasilkan skor + profil + rekomendasi dalam < ~1 detik. |
| AC-02 | Semua proses berjalan tanpa koneksi internet. |
| AC-03 | Defect rate = total biji defect / total biji terlihat. |
| AC-04 | Biji `Green` tidak menerima parameter seduh normal. |
| AC-05 | Confidence rendah menghasilkan status `uncertain`, bukan kelas paksa. |
| AC-06 | Parameter grind/air/suhu/waktu selalu berasal dari resep di knowledge base (bukan prediksi model). |
| AC-07 | Setiap parameter resep punya referensi sumber yang dapat dilacak. |
| AC-08 | Riwayat analisis tersimpan lokal dan dapat diekspor CSV. |
| AC-09 | Grade ditentukan dari pemetaan Quality Profile → Grade (bagian 8). |
| AC-10 | Tidak ada komponen timer interaktif di aplikasi. |

---

## 11. Glossary

| Istilah | Arti |
|---|---|
| Batch | Sekumpulan biji kopi dalam satu foto |
| Visible bean | Biji yang terlihat di permukaan foto |
| Defect rate | Rasio biji defect terhadap total biji terlihat |
| Quality Score | Skor 0–100 dari rule engine |
| Quality Profile | Kategori skor (High/Medium/Low) |
| Indicative Grade | Label grade tampilan (Specialty…Off Grade) |
| Knowledge Base | Basis data metode & resep seduh |
| Green bean | Biji mentah, belum di-roasting |
