# Roastmate

> **Analisis batch biji kopi dan rekomendasi seduh langsung dari perangkat.**

## Identitas Anggota

**Kelas: TI-3E**
| No. | Nama | NIM |
|---:|---|---|
| 1 | Ahmad Kevin Malik Zakaria | 244107020125 |
| 2 | Ghazwan Ababil | 244107020151 |
| 3 | Handino Asa Galih | 244107020237 |
| 4 | Muhammad Shabran | 244107020112 |
| 5 | Sultan Nashira Ariva | 244107020187 |

## Deskripsi Proyek

Roastmate adalah aplikasi mobile untuk menganalisis foto batch biji kopi. Aplikasi dirancang untuk mendeteksi dan mengklasifikasikan biji, menghitung profil kualitas batch, lalu menyarankan metode dan resep seduh awal.

Pemrosesan dirancang berjalan di perangkat: model visi menganalisis gambar, OpenCV menghitung karakteristik bentuk, sedangkan quality score dan rekomendasi seduh ditentukan oleh rule engine dan knowledge base.

## Framework, Bahasa Pemrograman & Prasyarat

### Stack

| Bagian              | Teknologi                                                   |
| ------------------- | ----------------------------------------------------------- |
| Framework aplikasi  | Flutter                                                     |
| Bahasa pemrograman  | Dart                                                        |
| On-device inference | TensorFlow Lite melalui `tflite_flutter`                    |
| Kamera              | Flutter `camera` plugin                                     |
| Analisis bentuk     | OpenCV                                                      |
| Penyimpanan lokal   | SQLite melalui `sqflite`                                    |
| State management    | Riverpod atau Provider (pilihan implementasi belum dikunci) |

Paket pendukung di atas merupakan stack rancangan; integrasi ML dan penyimpanan lokal akan ditambahkan sesuai tahap implementasi.

### Prasyarat

- Flutter SDK yang mendukung constraint Dart pada `mobile/pubspec.yaml` (`^3.14.0-183.0.dev`).
- Android SDK untuk menjalankan aplikasi Android; atau Xcode untuk iOS (minimum deployment target iOS 15.0).
- Emulator atau perangkat fisik yang kompatibel.

### Menjalankan aplikasi

```bash
cd mobile
flutter pub get
flutter run
```

## Fitur

- Memindai batch biji kopi menggunakan kamera atau memilih foto dari galeri.
- Mendeteksi biji yang terlihat dan mengklasifikasikan species, roast, serta defect.
- Menganalisis bentuk dan distribusi biji.
- Menampilkan Quality Score, Quality Profile, grade indikatif, jumlah biji, dan defect rate.
- Memberikan rekomendasi metode seduh serta parameter awal dari knowledge base resep.
- Menyimpan dan menelusuri riwayat analisis, termasuk filter berdasarkan species.
- Mengekspor ringkasan riwayat analisis dalam format CSV.
- Menampilkan katalog resep dan panduan penyajian langkah demi langkah.

## Alur Penggunaan

1. Buka **Beranda** dan pilih **Scan Batch Baru**.
2. Arahkan kamera ke batch biji kopi; periksa panduan framing dan pencahayaan.
3. Ambil foto. Aplikasi memeriksa kualitas gambar sebelum analisis.
4. Lihat **Detail Inspeksi**: jenis dan roast kopi, defect, skor kualitas, bukti visual, serta rekomendasi seduh.
5. Buka resep untuk melihat parameter dan panduan langkah penyajian.
6. Temukan analisis sebelumnya atau ekspor riwayat melalui tab **Analisis**. Jelajahi resep melalui tab **Seduh**.

Panduan resep dapat menampilkan target waktu sebagai teks statis. Aplikasi tidak menyediakan timer seduh interaktif.

## Struktur Proyek

```text
roastmate_app/
├── docs/                  # PRD, arsitektur ML/mobile, design system, keputusan
├── UI/                    # Mockup layar dan design system
├── mobile/                # Aplikasi Flutter
│   ├── lib/               # Kode aplikasi Dart
│   ├── test/              # Widget dan test aplikasi
│   ├── android/           # Proyek platform Android
│   ├── ios/               # Proyek platform iOS
│   ├── macos/              # Proyek platform macOS
│   ├── web/                # Target web Flutter
│   ├── linux/              # Proyek platform Linux
│   └── windows/            # Proyek platform Windows
└── README.md
```

## Mockup UI

Mockup sumber berada di folder [`UI/`](UI/).

| Layar / artefak                       | Mockup                                            |
| ------------------------------------- | ------------------------------------------------- |
| Beranda                               | [Beranda.png](UI/Beranda.png)                     |
| Scan Kamera                           | [Scan Kamera.png](UI/Scan%20Kamera.png)           |
| Hasil Analisis / Detail Inspeksi      | [Hasil Analisis.png](UI/Hasil%20Analisis.png)     |
| Riwayat Analisis                      | [Riwayat Analisis.png](UI/Riwayat%20Analisis.png) |
| Katalog Resep Seduh                   | [Resep Seduh.png](UI/Resep%20Seduh.png)           |
| Detail Resep — panduan langkah statis | [Detail Resep.png](UI/Detail%20Resep.png)         |
| Design System                         | [Design System.png](UI/Design%20System.png)       |

## Test Case

| ID    | Jenis     | Skenario                                               | Hasil yang diharapkan                                                          |
| ----- | --------- | ------------------------------------------------------ | ------------------------------------------------------------------------------ |
| TC-01 | Widget    | Membuka Beranda                                        | Ringkasan batch dan navigasi tampil dengan benar                               |
| TC-02 | Widget    | Membuka Riwayat Analisis dan menerapkan filter species | Daftar dan hasil filter sesuai data tersimpan                                  |
| TC-03 | Widget    | Membuka Detail Inspeksi                                | Skor, jumlah biji, defect, dan rekomendasi tampil konsisten                    |
| TC-04 | Widget    | Membuka Detail Resep                                   | Parameter dan panduan langkah statis tampil; tidak ada timer interaktif        |
| TC-05 | Unit      | Menghitung Quality Score dari statistik batch          | Skor 0–100 sesuai bobot rule engine yang dikonfigurasi                         |
| TC-06 | Unit      | Menghitung defect rate                                 | Total defect dibagi jumlah biji terlihat                                       |
| TC-07 | Unit      | Mengolah confidence rendah atau batch campuran         | Hasil ditandai `uncertain` / `Mixed`, tanpa memaksakan kelas                   |
| TC-08 | Unit      | Memilih metode dan resep dari knowledge base           | Metode serta parameter berasal dari resep bersumber                            |
| TC-09 | Integrasi | Scan → hasil → simpan → buka riwayat                   | Hasil analisis tersimpan lokal dan muncul di riwayat                           |
| TC-10 | Integrasi | Mengekspor riwayat ke CSV                              | File CSV berisi ringkasan analisis yang dipilih                                |
| TC-11 | On-device | Menjalankan analisis pada perangkat target             | Inferensi memenuhi sasaran latensi dan RAM arsitektur                          |
| TC-12 | Data      | Menguji foto batch DS010                               | Hasil deteksi, klasifikasi, dan metrik batch dapat dievaluasi terhadap anotasi |

## Sumber Dataset

| ID    | Dataset                               | Kegunaan                                                         | Sumber                                                                                                                                                                       |
| ----- | ------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DS001 | USK-COFFEE Arabica                    | Arabica hijau, morfologi, bentuk, dan kualitas pendukung         | [Sumber asli](https://coffee.comvislab-usk.org/) · [Mirror Kaggle](https://www.kaggle.com/datasets/ghazwanababil/usk-coffee-arabica)                                         |
| DS002 | Coffee Bean Grading Dataset           | Segmentasi biji, anotasi polygon, dan grading                    | [Hugging Face](https://huggingface.co/datasets/SamruddhK/coffee-bean-grading-dataset)                                                                                        |
| DS003 | Coffee Bean Dataset Resized 224×224   | Klasifikasi tingkat roast                                        | [Kaggle](https://www.kaggle.com/datasets/gpiosenka/coffee-bean-dataset-resized-224-x-224)                                                                                    |
| DS004 | RoastedCoffeeDefectDataset            | Klasifikasi defect biji roasted                                  | [Sumber asli GitHub](https://github.com/dont-text-me/RoastedCoffeeDefectDataset) · [Mirror Kaggle](https://www.kaggle.com/datasets/ghazwanababil/roastedcoffeedefectdataset) |
| DS005 | Coffee Bean Defect — NG               | Data supplemental untuk defect biner                             | [Roboflow Universe](https://universe.roboflow.com/roasted-coffee-bean-defect-detectionandy/coffee-bean-defect)                                                               |
| DS006 | Kopi Robusta dan Arabika              | Klasifikasi species dan roast                                    | [Roboflow Universe](https://universe.roboflow.com/tugas-akhir-8wmr1/kopi-robusta-dan-arabika)                                                                                |
| DS007 | Robusta Coffee Bean Defects           | Defect biji Robusta roasted                                      | [Roboflow Universe](https://universe.roboflow.com/roasted-coffee-bean-defect/robusta-coffee-bean-defects)                                                                    |
| DS008 | ROBUSTA DATASET UNCROPPED             | Referensi biji normal, broken, foreign matter, dan insect damage | [Roboflow Universe](https://universe.roboflow.com/renies-workspace/robusta-dataset-uncropped)                                                                                |
| DS009 | Coffee Beans Dataset 2 (Segmentation) | Dataset segmentasi alternatif / supplemental                     | [Roboflow Universe](https://universe.roboflow.com/new-workspace-cuswj/coffee-beans-dataset-2-segmentation)                                                                   |
| DS010 | Custom Mobile Batch Dataset           | Validasi kamera mobile dan kondisi dunia nyata                   | Dataset internal tim Roastmate; belum memiliki tautan publik                                                                                                                 |

> Dataset perlu diaudit, dipetakan labelnya, dan diperiksa duplikasi serta lisensinya sebelum digunakan bersama untuk training. URL, versi, revisi, lisensi, dan provenance dicatat dalam dokumentasi ML/registry proyek.
