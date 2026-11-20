// Laporan Proyek PBL Tahap Milestone 2 - Roastmate
// Dibangkitkan dari generator yang sama dengan berkas .docx.
#set page(paper: "a4", margin: (x: 2.2cm, y: 2.2cm), numbering: none)
#set text(font: "Times New Roman", size: 11pt, lang: "id")
#set par(justify: true, leading: 0.72em, spacing: 0.8em)
#show heading.where(level: 1): it => pagebreak(weak: true) + it
#show heading.where(level: 1): set text(size: 14pt, weight: "bold")
#show heading.where(level: 2): set text(size: 11.5pt, weight: "bold")
#show heading: it => {
  set par(justify: false)
  it
}
#show table: it => {
  set par(justify: false)
  it
}

#align(center)[
  #v(1.2cm)
  #text(size: 14pt, weight: "bold")[LAPORAN PROYEK PROJECT-BASED LEARNING (PBL)]
  #v(0.2cm)
  #text(size: 14pt, weight: "bold")[TAHAP MILESTONE 2]
  #v(1.2cm)
  #text(size: 15pt, weight: "bold")[
    Roastmate: Asisten Cerdas Penilaian Mutu Fisik Biji Kopi Berbasis Edge AI
    dan Panduan Seduh Interaktif Menggunakan Pendekatan Hibrida Dual-Track
  ]
  #v(1.1cm)
  #text(size: 12pt)[Tim hehe · Kelas TI-3E · Semester 5]
  #v(0.15cm)
  #text(size: 12pt)[Tahun Akademik 2025/2026]
  #v(0.8cm)
]

#align(center)[
  #table(
    columns: (auto, 7.4cm, auto),
    inset: 6pt,
    align: (center, left, center),
    stroke: 0.5pt,
    table.header([*No*], [*Nama*], [*NIM*]),
    [1], [Ahmad Kevin Malik Zakaria], [244107020125],
    [2], [Ghazwan Ababil], [244107020151],
    [3], [Handino Asa Galih R], [244107020237],
    [4], [Muhammad Shabran], [244107020112],
    [5], [Sultan Nashira Ariva], [244107020187],
  )
]

#align(center)[
  #v(1.6cm)
  #image("assets/laporan/logo-polinema.png", width: 3.4cm)
  #v(0.4cm)
  #text(size: 12pt)[
    POLITEKNIK NEGERI MALANG \
    JURUSAN TEKNOLOGI INFORMASI \
    PROGRAM STUDI TEKNIK INFORMATIKA \
    November 2026
  ]
]

#pagebreak()
#set page(numbering: "1", number-align: center)
#counter(page).update(1)

#heading(level: 1, outlined: false)[Daftar Isi]
#outline(title: none, indent: auto, depth: 2)

= Lembar Status Milestone 2
== S.1 Identitas, Dosen Pengampu, dan Dosen Rujukan
Peran tiap anggota dan perubahannya sejak Laporan Kemajuan Milestone 1.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2530fr, 0.2651fr, 0.4819fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Nama*],
    align(left)[*Peran saat ini*],
    align(left)[*Perubahan dari Milestone 1*],
  ),
  align(left)[Ahmad Kevin Malik Z],
  align(left)[Machine Learning Engineer],
  align(left)[Menambah pekerjaan integrasi model ke aplikasi: ekspor TFLite, penyusunan pipeline on-device, dan evaluasi model di perangkat.],
  align(left)[Ghazwan Ababil],
  align(left)[Backend dan Integrasi Data],
  align(left)[Menambah lingkup basis data ke skema v7, pengisian knowledge base 14 resep, upload foto ke Cloudinary, dan sinkronisasi riwayat ke Supabase.],
  align(left)[Handino Asa Galih R],
  align(left)[QA Lead dan System Analyst],
  align(left)[Menyusun kasus uji manual dan mencatat bug; pengujian otomatis dikerjakan bersama Ghazwan Ababil.],
  align(left)[Muhammad Shabran],
  align(left)[Project Manager dan UI/UX Designer],
  align(left)[Menambah fitur resep buatan pengguna (form, langkah dinamis, video) dan mengoordinasikan jadwal Minggu 9 sampai 12.],
  align(left)[Sultan Nashira A],
  align(left)[Mobile Developer],
  align(left)[Menambah auth gate, layar login, daftar, dan profil, serta layar Beranda yang membaca ringkasan dari SQLite.],
)
]
]
#v(6pt)
#v(8pt)
Dosen pengampu dan dosen rujukan kelas.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2771fr, 0.3976fr, 0.3253fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Mata kuliah*],
    align(left)[*Dosen pengampu*],
    align(left)[*Dosen rujukan kelas*],
  ),
  align(left)[Pemrograman Mobile],
  align(left)[Agung Nugroho Pramudhita, S.T., M.T.],
  align(left)[Belum ditetapkan],
  align(left)[Pemrograman Mesin],
  align(left)[Rachmad Imam Tarecha, S.Kom., M.Kom.],
  align(left)[Belum ditetapkan],
  align(left)[Penjaminan Mutu Perangkat Lunak],
  align(left)[Titis Octary Satrio, S.ST., M.MT.],
  align(left)[Belum ditetapkan],
)
]
]
#v(6pt)
== S.2 Status Milestone 2
Status: Lengkap.
Alur utama sudah berjalan dari ujung ke ujung. Foto batch diproses model deteksi dan tiga classifier on-device, hasilnya disimpan ke SQLite lebih dulu, lalu ditampilkan di Detail Inspeksi dan Riwayat, dan rekomendasi seduh diambil dari knowledge base berisi 14 resep. Sebanyak 278 pengujian otomatis lulus, 2 dilewati, dan flutter analyze tidak menemukan error. Hasil awal model: tingkat sangrai akurasi uji 92,74 persen dengan macro F1 0,9254, jenis biji 70,03 persen, cacat 77,61 persen, dan detektor mAP50 0,8248 pada validasi sintetis. Tiga hal belum selesai dan sudah masuk rencana Minggu 13: ekspor CSV masih berupa placeholder, analisis bentuk masih memakai geometri bounding box dan belum OpenCV, serta akurasi jenis biji belum cukup untuk dipakai di luar foto studio.
== S.3 Tindak Lanjut Milestone 1
Tidak ada umpan balik tertulis dari dosen pada Milestone 1. Baris di bawah adalah temuan yang dicatat tim sendiri di Laporan Kemajuan Milestone 1 beserta tindak lanjutnya.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.3253fr, 0.1807fr, 0.3735fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Temuan Milestone 1*],
    align(left)[*Dari mata kuliah*],
    align(left)[*Tindak lanjut*],
    align(center)[*Status*],
  ),
  align(left)[Integrasi awal model ke aplikasi belum ada; folder inference dan engines masih kosong],
  align(left)[Pemrograman Mesin],
  align(left)[Pipeline TFLite dan isolate dipasang di alur scan, mencakup detektor, tiga classifier, dan agregasi batch],
  align(center)[Selesai],
  align(left)[Knowledge base resep masih kosong sehingga layar resep memakai data contoh],
  align(left)[Pemrograman Mobile],
  align(left)[Knowledge base diisi 3 metode, 8 alat, dan 14 resep dengan sumber BR001 sampai BR004, lalu di-seed ke SQLite],
  align(center)[Selesai],
  align(left)[Model sangrai gagal pada domain lain, akurasi 33,92 persen pada foto Robusta DS006],
  align(left)[Pemrograman Mesin],
  align(left)[Model dilatih ulang dengan arsitektur MobileNetV3-Small pada data yang sudah dibersihkan, akurasi uji 92,74 persen],
  align(center)[Sebagian, uji foto lapangan belum],
  align(left)[Alur utama masih memakai data contoh],
  align(left)[Pemrograman Mobile],
  align(left)[Beranda, Riwayat, dan Detail Inspeksi membaca SQLite hasil inferensi nyata],
  align(center)[Selesai],
)
]
]
#v(6pt)
== S.4 Capaian Produk
Status fitur yang dijanjikan pada proposal beserta catatan kondisinya saat ini.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.4458fr, 0.1205fr, 0.4337fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Fitur*],
    align(center)[*Status*],
    align(left)[*Catatan*],
  ),
  align(left)[Scan kamera: pratinjau, zoom 0,5x sampai 2x, flash, galeri],
  align(center)[Selesai],
  align(left)[Tombol capture 72 dp, indikator pencahayaan tampil],
  align(left)[Input nama batch sebelum scan],
  align(center)[Selesai],
  align(left)[Layar Setup Scan, nama tersimpan pada kolom batch\_name],
  align(left)[Inferensi on-device: deteksi, jenis, sangrai, cacat],
  align(center)[Selesai],
  align(left)[Berjalan di isolate, model dimuat satu per satu lalu dibebaskan],
  align(left)[Detail Inspeksi: skor, defect rate, bukti visual, rekomendasi],
  align(center)[Selesai],
  align(left)[Membaca hasil dari SQLite berdasarkan analysisId],
  align(left)[Riwayat Analisis: daftar, filter jenis, hapus],
  align(center)[Selesai],
  align(left)[Hapus ikut menghapus defects dan rekomendasi via ON DELETE CASCADE],
  align(left)[Ekspor CSV riwayat],
  align(center)[Belum],
  align(left)[Tombol ada, isinya masih pesan bahwa fitur akan datang],
  align(left)[Katalog metode, detail resep, panduan langkah statis, video],
  align(center)[Selesai],
  align(left)[Video dibuka di aplikasi YouTube, tanpa player embed dan tanpa timer],
  align(left)[Resep buatan pengguna: tambah, hapus, detail, metode Lainnya],
  align(center)[Selesai],
  align(left)[Tersimpan di user\_brew\_recipes, aman dari reseed knowledge base],
  align(left)[Quality score dan profil dari rule engine],
  align(center)[Selesai],
  align(left)[Berbasis cacat saja dengan bobot keparahan per kelas],
  align(left)[Penanganan biji Green],
  align(center)[Selesai],
  align(left)[Menampilkan bahwa roasting diperlukan, tanpa parameter seduh normal],
  align(left)[Penanganan confidence rendah dan batch campuran],
  align(center)[Selesai],
  align(left)[Ambang jenis 0,70 menjadi Mixed, ambang sangrai 0,45 menjadi uncertain],
  align(left)[Akun: login, daftar, profil, logout],
  align(center)[Selesai],
  align(left)[Auth gate: tanpa sesi, semua layar fitur dialihkan ke login],
  align(left)[Sinkronisasi riwayat antar perangkat],
  align(center)[Sebagian],
  align(left)[Kode dan uji unit ada, pengujian dua perangkat belum dilakukan],
  align(left)[Image quality check yang menolak foto gelap atau blur],
  align(center)[Sebagian],
  align(left)[Baru indikator pencahayaan, belum ada penolakan otomatis],
  align(left)[Analisis bentuk dan keseragaman dengan OpenCV],
  align(center)[Belum],
  align(left)[Sementara memakai geometri bounding box, belum OpenCV],
)
]
]
#v(6pt)
#v(8pt)
Daftar periksa target Milestone 2 untuk program studi TI Semester 5.
#block(inset: (left: 0.6cm))[\[x\] alur utama aplikasi mobile berjalan]
#block(inset: (left: 0.6cm))[\[x\] model ML bisa dipanggil dari aplikasi]
#block(inset: (left: 0.6cm))[\[x\] hasil awal model tertulis]
#block(inset: (left: 0.6cm))[\[x\] draf Bab 1 sampai 3]
#block(inset: (left: 0.6cm))[\[x\] Bab 4 dengan minimal 10 kasus uji]
== S.5 Bukti
Pilihan bukti yang diserahkan tim.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2048fr, 0.2771fr, 0.5181fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Aspek*],
    align(left)[*Pilihan*],
    align(left)[*Tautan atau keterangan*],
  ),
  align(left)[Bentuk demo],
  align(left)[Video, maksimal 5 menit],
  align(left)[https://drive.google.com/file/d/1BDkgIDwbbKtpx5LzLJLArQuZd7efgj49/view],
  align(left)[Cara deploy],
  align(left)[Berkas instalasi APK],
  align(left)[https://github.com/AhmadKevin000/roastmate\_app/releases/tag/v1.0.0],
  align(left)[Repositori],
  align(left)[Git, branch development],
  align(left)[https://github.com/AhmadKevin000/roastmate\_app/tree/development],
  align(left)[Masukan pengguna],
  align(left)[Pengguna pengganti],
  align(left)[Lima anggota tim di luar perannya (uji internal); belum ada mitra. Rincian di Bab 4.5],
  align(left)[Bukti pengujian],
  align(left)[Uji otomatis dan uji manual],
  align(left)[278 pengujian otomatis lulus, 12 kasus uji manual di Bab 4.2],
)
]
]
#v(6pt)
== S.6 Rencana Minggu 13 sampai 16
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.1205fr, 0.6145fr, 0.2651fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*Minggu*],
    align(left)[*Target*],
    align(left)[*Penanggung jawab*],
  ),
  align(center)[13],
  align(left)[Implementasi ekspor CSV; perbaiki bug prioritas; uji foto nyata dari kamera ponsel],
  align(left)[Ababil, Dino],
  align(center)[14],
  align(left)[Analisis bentuk OpenCV; penambahan data latih jenis biji dari domain pengguna; uji dua perangkat untuk sinkronisasi],
  align(left)[Kevin, Sultan],
  align(center)[15],
  align(left)[Pengujian pengguna di luar tim; penyempurnaan Bab 1 sampai 5 dan Lampiran; materi demo],
  align(left)[Seluruh tim],
  align(center)[16],
  align(left)[Demo Day dan Expo; perbaikan temuan terakhir],
  align(left)[Seluruh tim],
)
]
]
#v(6pt)
= Bab 1. Pendahuluan
== 1.1 Latar Belakang dan Rumusan Masalah
Penilaian mutu fisik biji kopi umumnya dilakukan manual. Penguji mengamati warna, bentuk, dan cacat satu per satu, lalu memberi nilai berdasarkan pengalaman. Cara ini lambat, sulit diulang, dan hasil antar penguji bisa berbeda jauh. Peralatan grading laboratorium memang memberi hasil lebih konsisten, tetapi harganya tidak terjangkau bagi petani, roaster kecil, atau kedai kopi. Akibatnya banyak batch hanya dinilai dengan perkiraan, dan penentuan resep seduh awal dilakukan dengan coba-coba.
Roastmate menjawab dua masalah itu sekaligus. Dari satu foto batch, aplikasi mendeteksi setiap biji, mengklasifikasikan jenis, tingkat sangrai, dan cacatnya, lalu menghitung skor kualitas dengan aturan yang tetap dan dapat diulang. Skor itu dipakai untuk memilih metode dan resep seduh awal dari knowledge base. Seluruh pemrosesan berjalan di perangkat, sehingga alur analisis tidak membutuhkan koneksi internet.
Rumusan masalah yang dijawab produk:
- Bagaimana menilai mutu fisik batch biji kopi secara konsisten dari satu foto tanpa peralatan laboratorium.
- Bagaimana menerjemahkan hasil penilaian itu menjadi titik awal seduh yang masuk akal, tanpa mengarang angka.
- Bagaimana menjalankan deteksi, klasifikasi, dan perhitungan skor di ponsel dengan sumber daya terbatas.
== 1.2 Tujuan
- Membangun aplikasi mobile yang menganalisis satu foto batch biji kopi dan menghasilkan skor kualitas, profil, serta rekomendasi seduh.
- Menjalankan seluruh inferensi model visi di perangkat, tanpa mengirim foto ke server.
- Memisahkan peran model dan aturan: model hanya untuk penglihatan, sedangkan skor dan parameter seduh ditentukan rule engine dan knowledge base.
- Menyediakan riwayat analisis yang tersimpan lokal dan dapat disinkronkan antar perangkat setelah pengguna login.
== 1.3 Cakupan Fitur dan Batasan
Yang dikerjakan pada produk ini:
- Analisis satu foto batch: deteksi biji, klasifikasi jenis, tingkat sangrai, dan cacat, lalu agregasi batch.
- Skor kualitas, profil kualitas, dan rekomendasi metode seduh beserta parameter dari knowledge base.
- Riwayat analisis, detail inspeksi, katalog metode seduh, resep bawaan, dan resep buatan pengguna.
- Akun pengguna dan sinkronisasi riwayat antar perangkat.
#v(4pt)
Yang sengaja tidak dikerjakan:
- Timer seduh interaktif, baik hitung mundur maupun sinkronisasi waktu.
- Prediksi parameter seduh langsung oleh model machine learning.
- Prediksi kelembapan dan kontrol roasting otomatis.
- Sertifikasi laboratorium fisik; hasil aplikasi bersifat indikatif.
#v(4pt)
Asumsi yang dipakai:
- Foto diambil dari satu sudut pandang, dengan pencahayaan cukup, dan hanya biji yang terlihat di permukaan yang dinilai.
- Satu foto mewakili satu batch; pencampuran antar batch tidak dimodelkan.
- Parameter seduh selalu berasal dari resep yang punya sumber tercatat, bukan hasil prediksi model.
== 1.4 Pemangku Kepentingan dan Manfaat
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2651fr, 0.3494fr, 0.3855fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Pemangku kepentingan*],
    align(left)[*Kebutuhan*],
    align(left)[*Manfaat dari produk*],
  ),
  align(left)[Petani dan produsen],
  align(left)[Menilai mutu hasil panen dan roasting dengan cepat],
  align(left)[Skor dan rincian cacat bisa dipakai menyortir batch tanpa alat laboratorium],
  align(left)[Roaster],
  align(left)[Memeriksa konsistensi hasil sangrai antar batch],
  align(left)[Perbandingan skor dan sebaran tingkat sangrai antar batch tersimpan di riwayat],
  align(left)[Barista dan penggemar kopi],
  align(left)[Menentukan titik awal seduh],
  align(left)[Rekomendasi metode dan parameter awal yang bersumber, bukan tebakan],
  align(left)[Mahasiswa dan peneliti],
  align(left)[Data grading yang bisa diolah lagi],
  align(left)[Riwayat tersimpan lokal dan dapat diekspor],
  align(left)[Dosen pengampu],
  align(left)[Menilai ketercapaian capaian pembelajaran],
  align(left)[Bukti implementasi, pengujian, dan evaluasi model terdokumentasi],
)
]
]
#v(6pt)
== 1.5 Kriteria Keberhasilan
Ukuran yang dipakai tim untuk menilai keberhasilan, dirujuk kembali pada Bab 4.6.
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2048fr, 0.5663fr, 0.2289fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Aspek*],
    align(left)[*Ukuran*],
    align(left)[*Sumber*],
  ),
  align(left)[Waktu analisis],
  align(left)[Satu foto batch selesai di bawah sekitar 1 detik],
  align(left)[PRD AC-01],
  align(left)[Operasi],
  align(left)[Alur analisis berjalan tanpa koneksi internet],
  align(left)[PRD AC-02],
  align(left)[Skor kualitas],
  align(left)[Defect rate berbobot keparahan, skor 0 sampai 100],
  align(left)[PRD AC-03],
  align(left)[Biji Green],
  align(left)[Tidak menerima parameter seduh normal],
  align(left)[PRD AC-04],
  align(left)[Confidence rendah],
  align(left)[Ditandai Mixed atau uncertain, bukan dipaksa satu kelas],
  align(left)[PRD AC-05],
  align(left)[Parameter seduh],
  align(left)[Selalu berasal dari resep knowledge base yang punya sumber],
  align(left)[PRD AC-06 dan AC-07],
  align(left)[Riwayat],
  align(left)[Tersimpan lokal dan dapat diekspor],
  align(left)[PRD AC-08],
  align(left)[Model sangrai],
  align(left)[Macro F1 pada data uji minimal 0,85],
  align(left)[Target internal tim],
  align(left)[Pengujian],
  align(left)[Minimal 10 kasus uji alur utama dijalankan],
  align(left)[Template Milestone 2],
)
]
]
#v(6pt)
= Bab 2. Analisis Kebutuhan dan Perancangan
== 2.1 Kebutuhan Pengguna dan Daftar Fitur
Produk dipakai satu jenis peran pengguna, yaitu pengguna terdaftar. Setelah login, pengguna dapat memindai batch, melihat hasil, membuka riwayat, dan mengelola resep. Tidak ada peran admin atau staf pada versi ini.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.1 Kebutuhan fungsional produk]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.0964fr, 0.2530fr, 0.6506fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*Kode*],
    align(left)[*Kebutuhan fungsional*],
    align(left)[*Ringkasan perilaku*],
  ),
  align(center)[FR-01],
  align(left)[Scan kamera],
  align(left)[Pratinjau kamera, overlay panduan, indikator pencahayaan, zoom, flash, galeri, tombol capture minimal 48 dp],
  align(center)[FR-02],
  align(left)[Pemeriksaan kualitas foto],
  align(left)[Memberi peringatan bila foto gelap atau blur; penolakan otomatis belum ada],
  align(center)[FR-03],
  align(left)[Inferensi on-device],
  align(left)[Deteksi biji, crop dengan padding, resize 224 bilinear, klasifikasi jenis, sangrai, dan cacat],
  align(center)[FR-04],
  align(left)[Detail inspeksi],
  align(left)[Skor, jumlah biji, defect rate, narasi, rekomendasi utama dan alternatif, bukti visual, disclaimer],
  align(center)[FR-05],
  align(left)[Riwayat analisis],
  align(left)[Daftar, filter jenis, hapus dengan konfirmasi, ekspor CSV],
  align(center)[FR-06],
  align(left)[Katalog metode seduh],
  align(left)[Daftar metode, ringkasan parameter, tambah dan hapus resep pengguna],
  align(center)[FR-07],
  align(left)[Detail resep],
  align(left)[Parameter, alat, langkah statis dengan label waktu, video, tips; tanpa timer],
  align(center)[FR-08],
  align(left)[Penanganan biji Green],
  align(left)[Menampilkan bahwa roasting diperlukan dan tidak memberi parameter seduh],
  align(center)[FR-09],
  align(left)[Confidence dan batch campuran],
  align(left)[Ambang jenis 0,70 menjadi Mixed; ambang sangrai 0,45 menjadi uncertain],
  align(center)[FR-10],
  align(left)[Akun],
  align(left)[Login dan daftar dengan email dan sandi, profil, logout, auth gate],
  align(center)[FR-11],
  align(left)[Sinkronisasi riwayat],
  align(left)[Riwayat dan resep pengguna disinkronkan ke cloud secara best-effort, digabung berdasarkan uuid],
)
]
]
#v(6pt)
#v(8pt)
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.2 Kebutuhan non-fungsional]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2169fr, 0.3855fr, 0.3976fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Aspek*],
    align(left)[*Target*],
    align(left)[*Catatan*],
  ),
  align(left)[Platform],
  align(left)[Android dan iOS],
  align(left)[Pengujian berjalan di Android],
  align(left)[Mode operasi],
  align(left)[Offline-first untuk alur analisis],
  align(left)[Login dan sinkronisasi memerlukan internet],
  align(left)[Latensi inferensi],
  align(left)[Di bawah sekitar 1 detik per foto],
  align(left)[Diukur pada mesin pengembang, belum pada perangkat target],
  align(left)[Penggunaan RAM],
  align(left)[Di bawah sekitar 120 MB],
  align(left)[Belum diukur pada perangkat],
  align(left)[Ukuran model],
  align(left)[Sekitar 17 MB],
  align(left)[Detektor 6,1 MB ditambah tiga classifier 3,6 MB],
  align(left)[Bahasa antarmuka],
  align(left)[Indonesia],
  align(left)[Seluruh teks antarmuka],
  align(left)[Aksesibilitas],
  align(left)[Target sentuh minimal 48 dp, kontras teks minimal 4,5:1],
  align(left)[Diuji pada tombol utama],
)
]
]
#v(6pt)
== 2.2 Susunan Komponen Sistem
Aplikasi memakai pola MVVM dengan pembagian per fitur. Lapisan presentasi memegang widget dan view model, lapisan domain memegang entitas dan aturan, lapisan data memegang repositori dan sumber lokal. Arah ketergantungan satu arah: presentasi menuju domain, domain menuju data. Inference berada di lapisan terpisah karena berjalan di isolate.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.3 Komponen sistem dan alasan pemilihan]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2289fr, 0.2530fr, 0.5181fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Komponen*],
    align(left)[*Teknologi*],
    align(left)[*Alasan pemilihan*],
  ),
  align(left)[Aplikasi mobile],
  align(left)[Flutter dan Dart],
  align(left)[Satu basis kode untuk Android dan iOS, ekosistem plugin kamera dan SQLite matang],
  align(left)[Manajemen state],
  align(left)[Riverpod],
  align(left)[Tidak bergantung pada BuildContext, mudah di-override saat pengujian],
  align(left)[Navigasi],
  align(left)[GoRouter],
  align(left)[Route dideklarasikan terpusat, cocok untuk auth gate berbasis redirect],
  align(left)[Penyimpanan lokal],
  align(left)[SQLite melalui sqflite],
  align(left)[Relasional, mendukung foreign key dan cascade, cukup untuk knowledge base dan riwayat],
  align(left)[Inferensi],
  align(left)[tflite\_flutter],
  align(left)[Menjalankan model TFLite di perangkat tanpa dependensi layanan],
  align(left)[Kamera],
  align(left)[camera],
  align(left)[Pratinjau, zoom, flash, dan capture lintas platform],
  align(left)[Pengolahan citra],
  align(left)[image],
  align(left)[Crop, resize bilinear, dan konversi format sebelum inferensi],
  align(left)[Penyimpanan foto],
  align(left)[Cloudinary],
  align(left)[Foto bisa dibuka di perangkat lain setelah sinkronisasi; bersifat best-effort],
  align(left)[Akun dan sinkronisasi],
  align(left)[Supabase],
  align(left)[Autentikasi siap pakai, basis data relasional, dan RLS per pengguna],
  align(left)[Tema],
  align(left)[Inter dan token warna internal],
  align(left)[Konsistensi tampilan tanpa nilai warna yang ditulis langsung di widget],
)
]
]
#v(6pt)
== 2.3 Rancangan Basis Data
Basis data berupa satu SQLite lokal dengan sembilan tabel, ditambah empat tabel di cloud yang mencerminkan tabel riwayat. Tabel dikelompokkan menjadi knowledge base (statis), riwayat (ditulis saat analisis), dan data pengguna. Diagram relasi utama: brew\_methods memiliki banyak brew\_recipes dan banyak brew\_method\_tools; brew\_method\_tools menghubungkan brew\_methods dengan brew\_tools; analyses memiliki banyak analysis\_defects dan satu recommendations; recommendations merujuk ke brew\_methods dan brew\_recipes; user\_brew\_recipes merujuk ke brew\_methods.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.4 Daftar tabel basis data]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2410fr, 0.1807fr, 0.2048fr, 0.3735fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Tabel*],
    align(left)[*Kelompok*],
    align(left)[*Kunci utama*],
    align(left)[*Keterangan*],
  ),
  align(left)[brew\_methods],
  align(left)[Knowledge base],
  align(left)[method\_id],
  align(left)[Metadata metode seduh],
  align(left)[brew\_tools],
  align(left)[Knowledge base],
  align(left)[tool\_id],
  align(left)[Master alat seduh],
  align(left)[brew\_method\_tools],
  align(left)[Knowledge base],
  align(left)[method\_id + tool\_id],
  align(left)[Tabel penghubung metode dan alat],
  align(left)[brew\_recipes],
  align(left)[Knowledge base],
  align(left)[recipe\_id],
  align(left)[Parameter seduh beserta sumber],
  align(left)[analyses],
  align(left)[Riwayat],
  align(left)[id],
  align(left)[Satu sesi analisis batch, ditambah uuid untuk sinkronisasi],
  align(left)[analysis\_defects],
  align(left)[Riwayat],
  align(left)[id],
  align(left)[Jumlah per kelas cacat pada satu analisis],
  align(left)[recommendations],
  align(left)[Riwayat],
  align(left)[id],
  align(left)[Metode utama, metode alternatif, dan alasan],
  align(left)[user\_brew\_recipes],
  align(left)[Data pengguna],
  align(left)[recipe\_id],
  align(left)[Resep buatan pengguna, di luar knowledge base],
  align(left)[meta],
  align(left)[Internal],
  align(left)[key],
  align(left)[Versi skema dan versi knowledge base],
)
]
]
#v(6pt)
#v(8pt)
Kamus data untuk tabel yang paling sering dipakai.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.5 Kamus data sebagian kolom]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.3012fr, 0.1325fr, 0.3012fr, 0.2651fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Tabel dan kolom*],
    align(left)[*Tipe*],
    align(left)[*Batasan*],
    align(left)[*Keterangan*],
  ),
  align(left)[analyses.id],
  align(left)[INTEGER],
  align(left)[PK, autoincrement],
  align(left)[Kunci lokal],
  align(left)[analyses.uuid],
  align(left)[TEXT],
  align(left)[unik],
  align(left)[Kunci identitas lintas perangkat],
  align(left)[analyses.sync\_status],
  align(left)[TEXT],
  align(left)[local, pending, synced],
  align(left)[Status sinkronisasi],
  align(left)[analyses.species],
  align(left)[TEXT],
  align(left)[Arabica, Robusta, Liberika, Mixed],
  align(left)[Hasil klasifikasi jenis],
  align(left)[analyses.roast],
  align(left)[TEXT],
  align(left)[Green, Light, Medium, Dark],
  align(left)[Hasil klasifikasi sangrai],
  align(left)[analyses.visible\_beans],
  align(left)[INTEGER],
  align(left)[boleh null],
  align(left)[Jumlah biji terdeteksi],
  align(left)[analyses.defect\_rate],
  align(left)[REAL],
  align(left)[boleh null],
  align(left)[Defect rate berbobot],
  align(left)[analyses.quality\_score],
  align(left)[INTEGER],
  align(left)[boleh null],
  align(left)[Skor 0 sampai 100],
  align(left)[analysis\_defects.defect\_class],
  align(left)[TEXT],
  align(left)[Normal, Quaker, Broken, Severe],
  align(left)[Empat kelas cacat final],
  align(left)[analysis\_defects.count],
  align(left)[INTEGER],
  align(left)[default 0],
  align(left)[Jumlah biji per kelas],
  align(left)[brew\_recipes.source],
  align(left)[TEXT],
  align(left)[NOT NULL],
  align(left)[Kode sumber parameter, misalnya BR001],
  align(left)[brew\_recipes.steps],
  align(left)[TEXT],
  align(left)[boleh null],
  align(left)[Langkah seduh tersimpan sebagai JSON],
  align(left)[recommendations.analysis\_id],
  align(left)[INTEGER],
  align(left)[FK, unik],
  align(left)[Satu rekomendasi per analisis],
)
]
]
#v(6pt)
#v(8pt)
Normalisasi. Tabel knowledge base memenuhi bentuk normal ketiga: setiap kolom bergantung pada kunci utama tabelnya, dan relasi banyak ke banyak antara metode dan alat dipisahkan ke brew\_method\_tools. Tabel riwayat juga memenuhi bentuk normal ketiga, kecuali dua kolom yang sengaja didenormalisasi, yaitu analyses.roast\_distribution dan brew\_recipes.steps. Keduanya disimpan sebagai JSON karena selalu dibaca dan ditulis sebagai satu kesatuan, tidak pernah difilter per elemen, dan memecahnya menjadi tabel tambahan hanya menambah join tanpa manfaat. Trade-off ini dicatat, bukan kelalaian.
== 2.4 Rancangan Model Machine Learning
Ada empat model dengan tugas terpisah. Detektor YOLOv8n menemukan kotak setiap biji. Tiga classifier MobileNetV3-Small menilai jenis, tingkat sangrai, dan cacat per biji. Model tidak pernah mengeluarkan parameter seduh; keluarannya hanya label dan probabilitas.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.6 Rancangan model dan ukuran hasil yang ditargetkan]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.1928fr, 0.2651fr, 0.2651fr, 0.1446fr, 0.1325fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Model*],
    align(left)[*Tugas*],
    align(left)[*Kelas keluaran*],
    align(center)[*Ukuran target*],
    align(left)[*Rincian*],
  ),
  align(left)[Detektor],
  align(left)[Menemukan kotak biji],
  align(left)[satu kelas, bean],
  align(center)[mAP50 minimal 0,80],
  align(left)[Lampiran F.3],
  align(left)[Classifier jenis],
  align(left)[Jenis biji per biji],
  align(left)[Arabica, Robusta, Liberika],
  align(center)[Akurasi minimal 0,85],
  align(left)[Lampiran F.4],
  align(left)[Classifier sangrai],
  align(left)[Tingkat sangrai per biji],
  align(left)[Green, Light, Medium, Dark],
  align(center)[Macro F1 minimal 0,85],
  align(left)[Lampiran F.4],
  align(left)[Classifier cacat],
  align(left)[Kelas cacat per biji],
  align(left)[Normal, Quaker, Broken, Severe],
  align(center)[Akurasi minimal 0,80],
  align(left)[Lampiran F.4],
)
]
]
#v(6pt)
#v(8pt)
Agregasi batch mengubah keluaran per biji menjadi satu ringkasan. Jenis biji diambil dari rata-rata probabilitas seluruh biji, dan bila keyakinan tertinggi di bawah 0,70 hasilnya menjadi Mixed. Tingkat sangrai diambil dengan cara yang sama, dan bila di bawah 0,45 hasilnya ditandai uncertain. Defect rate dihitung sebagai jumlah bobot keparahan dibagi jumlah biji terlihat, dengan bobot Normal 0,0, Broken 0,3, Quaker 0,7, dan Severe 1,0.
== 2.5 Rancangan Antarmuka
Rancangan antarmuka disusun sebagai mockup terlebih dahulu, lalu diterapkan ke Flutter memakai token warna dan tipografi. Folder UI berisi enam mockup layar dan satu berkas design system; tujuh layar sudah berjalan di aplikasi.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 2.7 Layar aplikasi dan route]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2530fr, 0.2651fr, 0.4819fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Layar*],
    align(left)[*Route*],
    align(left)[*Isi utama*],
  ),
  align(left)[Beranda],
  align(left)[/home],
  align(left)[Ringkasan komposisi jenis, total analisis, rata-rata skor, tombol Scan Batch Baru, daftar analisis terakhir],
  align(left)[Setup Scan],
  align(left)[/scan/setup],
  align(left)[Input nama jenis biji sebelum membuka kamera],
  align(left)[Scan Kamera],
  align(left)[/scan],
  align(left)[Pratinjau, overlay panduan, indikator pencahayaan, zoom, flash, galeri, tombol capture],
  align(left)[Detail Inspeksi],
  align(left)[/result/:analysisId],
  align(left)[Skor, jumlah biji, defect rate, narasi, rekomendasi utama dan alternatif, bukti visual],
  align(left)[Riwayat Analisis],
  align(left)[/history],
  align(left)[Daftar analisis, filter jenis, hapus, kartu ekspor CSV],
  align(left)[Katalog Metode Seduh],
  align(left)[/brewing],
  align(left)[Tiga metode, ringkasan parameter, seksi Resep Kamu, tombol tambah],
  align(left)[Detail Resep],
  align(left)[/brewing/:methodId],
  align(left)[Parameter, alat, langkah statis, video, tips],
  align(left)[Detail Resep Kamu],
  align(left)[/brewing/user/:recipeId],
  align(left)[Resep buatan pengguna beserta langkah dan video],
  align(left)[Login, Daftar, Profil],
  align(left)[/login, /register, /profile],
  align(left)[Autentikasi dan logout],
)
]
]
#v(6pt)
#v(8pt)
Warna memakai palet bernuansa kopi: primary 5A382C, secondary 8B5E3C, background F7F3EE, surface FFFDF9, teks utama 211A17, teks sekunder 625850. Tipografi memakai Inter dengan bobot 400 sampai 700 dan ukuran 12 sampai 36 sp. Warna status cacat dibedakan per kelas: Normal 5E6B4A, Quaker C49038, Broken 9B6A3D, Severe B54A43. Tampilan akhir tiap layar ada di Lampiran A.
== 2.6 Rancangan Laporan atau Dasbor
Produk tidak memiliki laporan atau dasbor tersendiri. Ringkasan statistik disajikan di layar Beranda dalam bentuk komposisi jenis biji, total analisis, dan rata-rata skor.
= Bab 3. Implementasi
== 3.1 Teknologi yang Dipakai
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 3.1 Teknologi dan versi]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2771fr, 0.7229fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Bagian*],
    align(left)[*Teknologi dan versi*],
  ),
  align(left)[Bahasa dan framework],
  align(left)[Dart dengan constraint 3.14.0-183.0.dev, Flutter SDK],
  align(left)[Manajemen state],
  align(left)[flutter\_riverpod 2.5.1],
  align(left)[Navigasi],
  align(left)[go\_router 14.8.1],
  align(left)[Basis data lokal],
  align(left)[sqflite 2.4.2, ditambah sqflite\_common\_ffi 2.3.4 untuk pengujian],
  align(left)[Inferensi],
  align(left)[tflite\_flutter 0.12.1],
  align(left)[Kamera],
  align(left)[camera 0.10.5+9],
  align(left)[Pengolahan citra],
  align(left)[image 4.5.4, path\_provider 2.1.5],
  align(left)[Akun dan sinkronisasi],
  align(left)[supabase\_flutter 2.5.0, uuid 4.5.1],
  align(left)[Upload foto],
  align(left)[cloudinary 2.1.1, flutter\_dotenv 6.0.2],
  align(left)[Pembuka tautan],
  align(left)[url\_launcher 6.3.3],
  align(left)[Tipografi],
  align(left)[google\_fonts 6.2.1 dan berkas Inter lokal],
  align(left)[Pelatihan model],
  align(left)[Python, PyTorch, Ultralytics, TensorFlow Lite, dijalankan di Kaggle],
)
]
]
#v(6pt)
== 3.2 Cara Membuat Tiap Fitur
Alur scan. Layar Setup Scan menyimpan nama batch pada provider, lalu membuka kamera. Saat tombol capture ditekan, foto diambil, pratinjau kamera dimatikan lebih dulu agar memori lega, lalu pipeline inferensi dipanggil.
Pipeline inferensi berjalan di isolate terpisah supaya antarmuka tidak membeku. Model dimuat satu per satu dari aset ke berkas sementara, dipakai, lalu dibebaskan. Urutannya: deteksi biji, crop dengan padding 10 persen, resize 224 bilinear, klasifikasi jenis, sangrai, dan cacat untuk setiap biji, lalu agregasi batch.
Setelah ringkasan batch terbentuk, aplikasi menyimpan lebih dulu ke SQLite dalam satu transaksi: baris analyses, baris analysis\_defects, dan baris recommendations. Rekomendasi dipilih dari knowledge base dengan kunci jenis dan tingkat sangrai, lalu narasinya diambil dari template alasan. Upload foto ke Cloudinary dijalankan setelah penyimpanan dan bersifat best-effort; bila gagal atau offline, kolom image\_path tetap berisi path lokal dan alur tidak terhenti.
Rule engine skor kualitas dibuat sebagai kelas murni tanpa dependensi basis data atau jaringan, sehingga bisa diuji langsung.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 3.2 Aturan perhitungan skor kualitas]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.5181fr, 0.4819fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Rumus*],
    align(left)[*Keterangan*],
  ),
  align(left)[defect\_rate = jumlah(count x bobot) / jumlah biji terlihat],
  align(left)[Bobot per kelas: Normal 0,0, Broken 0,3, Quaker 0,7, Severe 1,0],
  align(left)[quality\_score = bulat(100 x (1 - defect\_rate))],
  align(left)[Hasil 0 sampai 100],
  align(left)[profil: High bila skor minimal 75, Medium minimal 60, selain itu Low],
  align(left)[Ambang dapat dikonfigurasi],
)
]
]
#v(6pt)
#v(8pt)
Auth gate. Router memakai redirect berbasis sesi Supabase. Tanpa sesi, setiap route fitur dialihkan ke /login. Bila kredensial Supabase tidak dikonfigurasi, gate dinonaktifkan dan aplikasi berjalan penuh secara offline. Sesi disimpan oleh SDK, sehingga login hanya sekali kecuali pengguna logout.
Sinkronisasi. Setiap baris riwayat membawa uuid yang dibuat di perangkat, user\_id, sync\_status, dan updated\_at. Penggabungan memakai union berdasarkan uuid, bersifat append-only, dan pengiriman dilakukan best-effort. Baris yang belum terkirim tetap berstatus pending dan dikirim saat daring berikutnya.
Resep pengguna. Form menampung metode dari knowledge base atau metode Lainnya dengan nama bebas, parameter penuh, langkah dinamis, dan tautan video. Langkah disimpan sebagai JSON pada kolom steps. Resep pengguna berada di tabel terpisah sehingga tidak tersentuh saat knowledge base di-seed ulang.
== 3.3 Basis Data
Skema berjalan dari versi 1 sampai versi 7. Setiap perubahan menaikkan nomor versi dan menambah migrasi, sehingga basis data lama di perangkat tidak perlu dihapus.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 3.3 Riwayat versi skema]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.1084fr, 0.8916fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*Versi*],
    align(left)[*Perubahan utama*],
  ),
  align(center)[1],
  align(left)[Sembilan tabel dasar: knowledge base, analyses, analysis\_defects, recommendations, meta],
  align(center)[2],
  align(left)[Kolom batch\_label, batch\_name, dan model\_version pada analyses],
  align(center)[3],
  align(left)[Penyelarasan taksonomi cacat dari enam kelas menjadi empat kelas],
  align(center)[4],
  align(left)[Tabel user\_brew\_recipes untuk resep buatan pengguna],
  align(center)[5],
  align(left)[Perbaikan kolom analyses dari basis data versi lama agar insert tidak gagal],
  align(center)[6],
  align(left)[Rebuild user\_brew\_recipes: langkah, metode Lainnya, video; kolom video\_url pada knowledge base],
  align(center)[7],
  align(left)[Kolom uuid, user\_id, sync\_status, dan updated\_at untuk sinkronisasi],
)
]
]
#v(6pt)
#v(8pt)
Knowledge base di-seed dari berkas JSON ke SQLite saat basis data pertama kali dibuat. Isinya 3 metode seduh, 8 alat, dan 14 resep yang mencakup empat jenis biji dan tiga tingkat sangrai. Setiap resep membawa kode sumber BR001 sampai BR004, sesuai aturan bahwa parameter seduh harus dapat dilacak. Data uji untuk pengembangan memakai 12 template analisis dan satu foto contoh batch.
== 3.4 Model dan Cara Memasangnya ke Aplikasi
Empat model diekspor ke TFLite dan disalin ke folder aset aplikasi. Detektor diekspor dalam fp16, sedangkan ketiga classifier memakai fp32 karena kuantisasi INT8 menurunkan kesesuaian argmax.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 3.4 Model yang terpasang di aplikasi]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.3373fr, 0.2410fr, 0.1446fr, 0.2771fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Berkas*],
    align(left)[*Peran*],
    align(center)[*Ukuran*],
    align(left)[*Catatan*],
  ),
  align(left)[bean\_detection.tflite],
  align(left)[Detektor biji],
  align(center)[6,1 MB],
  align(left)[YOLOv8n, fp16],
  align(left)[species\_classifier.tflite],
  align(left)[Classifier jenis],
  align(center)[3,6 MB],
  align(left)[MobileNetV3-Small, fp32],
  align(left)[roast\_classifier.tflite],
  align(left)[Classifier sangrai],
  align(center)[3,6 MB],
  align(left)[MobileNetV3-Small, fp32],
  align(left)[defect\_classifier.tflite],
  align(left)[Classifier cacat],
  align(center)[3,6 MB],
  align(left)[MobileNetV3-Small, fp32],
)
]
]
#v(6pt)
#v(8pt)
Pemasangan dilakukan tanpa konversi ulang di perangkat. Model disalin dari aset ke direktori sementara sekali saja melalui cache, lalu jalur berkasnya diberikan ke isolate. Isolate membuka interpreter TFLite, menjalankan inferensi, dan mengembalikan label beserta probabilitas. Label kelas disimpan pada satu berkas pemetaan agar urutan kelas konsisten dengan saat pelatihan. Rincian pelatihan dan evaluasi ada di Lampiran F.
== 3.5 Penyambungan antar Bagian dan Deploy
Rangkaian lengkapnya: kamera menghasilkan berkas foto, pipeline inferensi menghasilkan ringkasan batch, pembangun hasil mengubahnya menjadi entitas hasil analisis, repositori menyimpannya ke SQLite bersama rekomendasi, layanan Cloudinary mengunggah foto, lalu router membuka Detail Inspeksi memakai analysisId. Bila penyimpanan gagal, layar hasil tetap terbuka memakai data di memori dan pengguna diberi tahu lewat notifikasi singkat.
Deploy dilakukan sebagai berkas APK rilis yang dibangun dari branch development. Kredensial Cloudinary dan Supabase dibaca dari berkas .env yang tidak masuk repositori; contoh kuncinya disediakan pada .env.example. Tanpa .env, upload dan sinkronisasi nonaktif, tetapi alur analisis dan riwayat lokal tetap berjalan.
= Bab 4. Pengujian dan Evaluasi
== 4.1 Rencana Pengujian
Pengujian dibagi menjadi empat lapis. Uji unit menguji aturan yang murni seperti skor kualitas dan agregasi batch. Uji widget menguji layar dengan data terkendali. Uji integrasi menguji rangkaian dari capture sampai riwayat memakai basis data SQLite di memori. Uji on-device menguji pipeline nyata dengan model TFLite yang sebenarnya. Alat yang dipakai adalah flutter\_test, sqflite\_common\_ffi untuk basis data di memori, dan perangkat Android untuk uji manual.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.1 Rencana pengujian per lapis]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.1687fr, 0.5060fr, 0.2048fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Jenis uji*],
    align(left)[*Cakupan*],
    align(left)[*Alat*],
    align(center)[*Jumlah berkas*],
  ),
  align(left)[Unit],
  align(left)[Rule engine, agregasi batch, penolakan label, postprocess detektor, konversi citra],
  align(left)[flutter\_test],
  align(center)[6],
  align(left)[Widget],
  align(left)[Beranda, riwayat, detail inspeksi, katalog, detail resep, form resep, login, header],
  align(left)[flutter\_test],
  align(center)[14],
  align(left)[Integrasi],
  align(left)[Capture sampai simpan, hapus riwayat, repositori, sinkronisasi, Cloudinary],
  align(left)[sqflite\_common\_ffi],
  align(center)[8],
  align(left)[On-device],
  align(left)[Pipeline nyata dengan empat model TFLite],
  align(left)[flutter\_test dengan model asli],
  align(center)[1],
  align(left)[Skema],
  align(left)[Struktur tabel, batasan, migrasi, index],
  align(left)[sqflite\_common\_ffi],
  align(center)[2],
)
]
]
#v(6pt)
#v(8pt)
Hasil eksekusi: 278 pengujian lulus, 2 dilewati, 0 gagal, pada 40 berkas uji. flutter analyze melaporkan 0 error dan 0 warning, dengan 20 catatan informatif mengenai gaya penulisan.
== 4.2 Kasus Uji dan Hasil
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.2 Kasus uji alur utama dan hasilnya]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0783fr, 0.2048fr, 0.2048fr, 0.2048fr, 0.2169fr, 0.0904fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*ID*],
    align(left)[*Skenario*],
    align(left)[*Langkah singkat*],
    align(left)[*Hasil diharapkan*],
    align(left)[*Hasil aktual*],
    align(center)[*Status*],
  ),
  align(center)[TC-01],
  align(left)[Membuka Beranda],
  align(left)[Buka aplikasi setelah login],
  align(left)[Ringkasan dan navigasi tampil],
  align(left)[Ringkasan dari SQLite tampil],
  align(center)[Lulus],
  align(center)[TC-02],
  align(left)[Riwayat dan filter jenis],
  align(left)[Buka Riwayat, pilih filter Arabica],
  align(left)[Daftar sesuai data tersimpan],
  align(left)[Filter menyaring benar],
  align(center)[Lulus],
  align(center)[TC-03],
  align(left)[Membuka Detail Inspeksi],
  align(left)[Buka hasil dari riwayat],
  align(left)[Skor, biji, cacat, rekomendasi konsisten],
  align(left)[Tampil sesuai baris basis data],
  align(center)[Lulus],
  align(center)[TC-04],
  align(left)[Membuka Detail Resep],
  align(left)[Buka V60 dari katalog],
  align(left)[Parameter dan langkah statis tampil, tanpa timer],
  align(left)[Tampil, tidak ada timer],
  align(center)[Lulus],
  align(center)[TC-05],
  align(left)[Menghitung skor kualitas],
  align(left)[Masukkan sebaran cacat uji],
  align(left)[Skor sesuai rumus bobot],
  align(left)[Sesuai, termasuk kasus nol biji],
  align(center)[Lulus],
  align(center)[TC-06],
  align(left)[Menghitung defect rate],
  align(left)[Masukkan campuran kelas cacat],
  align(left)[Jumlah bobot dibagi biji terlihat],
  align(left)[Sesuai],
  align(center)[Lulus],
  align(center)[TC-07],
  align(left)[Confidence rendah dan batch campuran],
  align(left)[Masukkan probabilitas di bawah ambang],
  align(left)[Menjadi Mixed atau uncertain],
  align(left)[Sesuai ambang 0,70 dan 0,45],
  align(center)[Lulus],
  align(center)[TC-08],
  align(left)[Rekomendasi dari knowledge base],
  align(left)[Cari resep untuk jenis dan sangrai],
  align(left)[Parameter berasal dari resep bersumber],
  align(left)[Resep dan kode sumber terpilih benar],
  align(center)[Lulus],
  align(center)[TC-09],
  align(left)[Scan sampai riwayat],
  align(left)[Ambil foto, simpan, buka riwayat],
  align(left)[Baris baru muncul di riwayat],
  align(left)[Muncul beserta cacat dan rekomendasi],
  align(center)[Lulus],
  align(center)[TC-10],
  align(left)[Ekspor riwayat ke CSV],
  align(left)[Tekan tombol ekspor],
  align(left)[Berkas CSV berisi ringkasan],
  align(left)[Muncul pesan bahwa fitur belum tersedia],
  align(center)[Gagal],
  align(center)[TC-11],
  align(left)[Analisis pada perangkat],
  align(left)[Jalankan pipeline dengan model asli],
  align(left)[Memenuhi sasaran latensi dan RAM],
  align(left)[336 ms di mesin pengembang, RAM belum diukur],
  align(center)[Sebagian],
  align(center)[TC-12],
  align(left)[Foto batch nyata],
  align(left)[Uji foto dari kamera ponsel dengan anotasi],
  align(left)[Hasil dapat dievaluasi terhadap anotasi],
  align(left)[Dataset anotasi foto nyata belum ada],
  align(center)[Belum],
)
]
]
#v(6pt)
#v(8pt)
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.3 Pemetaan kasus uji ke kebutuhan]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2530fr, 0.7470fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Kasus uji*],
    align(left)[*Kebutuhan yang diuji*],
  ),
  align(left)[TC-01, TC-03],
  align(left)[FR-04 Detail inspeksi],
  align(left)[TC-02],
  align(left)[FR-05 Riwayat analisis],
  align(left)[TC-04],
  align(left)[FR-06 dan FR-07 Katalog serta detail resep],
  align(left)[TC-05, TC-06],
  align(left)[FR-04 dan AC-03 Skor kualitas],
  align(left)[TC-07],
  align(left)[FR-09 Confidence dan batch campuran],
  align(left)[TC-08],
  align(left)[FR-04, AC-06, dan AC-07 Sumber parameter],
  align(left)[TC-09],
  align(left)[FR-01, FR-03, dan FR-05 Alur scan sampai riwayat],
  align(left)[TC-10],
  align(left)[FR-05 dan AC-08 Ekspor CSV],
  align(left)[TC-11],
  align(left)[FR-03 dan NFR latensi],
  align(left)[TC-12],
  align(left)[FR-03 dan NFR ukuran model],
)
]
]
#v(6pt)
== 4.3 Bug yang Ditemukan
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.4 Bug yang ditemukan dan statusnya]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0843fr, 0.2771fr, 0.1084fr, 0.2530fr, 0.1084fr, 0.1687fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*ID*],
    align(left)[*Bug*],
    align(center)[*Keparahan*],
    align(left)[*Langkah mereproduksi*],
    align(center)[*Status*],
    align(left)[*Rencana*],
  ),
  align(center)[BUG-01],
  align(left)[Kartu skor dan kartu rekomendasi meluber pada layar sempit],
  align(center)[Sedang],
  align(left)[Buka Detail Inspeksi pada layar lebar di bawah 360 dp],
  align(center)[Diperbaiki],
  align(left)[Selesai 12 Oktober 2026],
  align(center)[BUG-02],
  align(left)[Kamera tetap aktif setelah meninggalkan layar scan],
  align(center)[Sedang],
  align(left)[Buka scan lalu tekan kembali],
  align(center)[Diperbaiki],
  align(left)[Selesai 13 Oktober 2026],
  align(center)[BUG-03],
  align(left)[Insert analyses gagal pada basis data dari versi lama],
  align(center)[Tinggi],
  align(left)[Pasang aplikasi baru di atas basis data lama lalu lakukan scan],
  align(center)[Diperbaiki],
  align(left)[Migrasi idempoten pada skema v5],
  align(center)[BUG-04],
  align(left)[Kolom analyses tidak cocok dengan basis data lama sehingga aplikasi berhenti],
  align(center)[Tinggi],
  align(left)[Buka Riwayat pada basis data lama],
  align(center)[Diperbaiki],
  align(left)[Perbaikan kolom pada skema v5],
  align(center)[BUG-05],
  align(left)[Ekspor CSV belum menghasilkan berkas],
  align(center)[Rendah],
  align(left)[Tekan tombol ekspor pada Riwayat],
  align(center)[Terbuka],
  align(left)[Direncanakan Minggu 13],
  align(center)[BUG-06],
  align(left)[Peringatan penggunaan BuildContext setelah operasi asinkron pada alur scan],
  align(center)[Rendah],
  align(left)[Jalankan flutter analyze],
  align(center)[Terbuka],
  align(left)[Perbaikan kecil, dijadwalkan Minggu 13],
)
]
]
#v(6pt)
== 4.4 Hasil Awal Model
Model dievaluasi pada data uji terpisah dan pada validasi silang, bergantung pada jumlah data tiap tugas. Angka di bawah berasal dari keluaran pelatihan yang tersimpan di folder plots, dan rincian per kelas ada di Lampiran F.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.5 Hasil awal model]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2289fr, 0.2771fr, 0.2289fr, 0.1446fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Model*],
    align(left)[*Data evaluasi*],
    align(left)[*Metrik utama*],
    align(center)[*Hasil*],
    align(left)[*Target*],
  ),
  align(left)[Classifier sangrai],
  align(left)[Uji, 179 gambar],
  align(left)[Akurasi / macro F1],
  align(center)[0,9274 / 0,9254],
  align(left)[F1 minimal 0,85],
  align(left)[Classifier jenis],
  align(left)[Split resmi, 287 gambar],
  align(left)[Akurasi / macro F1],
  align(center)[0,7003 / 0,6910],
  align(left)[Akurasi minimal 0,85],
  align(left)[Classifier cacat],
  align(left)[Validasi silang 5 lipat],
  align(left)[Akurasi / macro F1],
  align(center)[0,7761 / 0,6465],
  align(left)[Akurasi minimal 0,80],
  align(left)[Detektor biji],
  align(left)[Validasi sintetis, 40 gambar],
  align(left)[mAP50 / mAP50-95],
  align(center)[0,8248 / 0,5032],
  align(left)[mAP50 minimal 0,80],
)
]
]
#v(6pt)
#v(8pt)
Hanya classifier sangrai yang sudah melewati target. Classifier jenis tertinggal paling jauh: akurasi 0,7003 berarti sekitar tiga dari sepuluh biji salah jenis, dan dengan ambang 0,70 hanya 65,52 persen biji yang lolos tanpa menjadi Mixed. Classifier cacat lolos target akurasi tetapi macro F1 hanya 0,6465 karena kelas Broken paling lemah, dengan recall 0,4828. Detektor memenuhi target mAP50, tetapi angka itu diukur pada validasi sintetis hasil tempel-salin biji, bukan foto nampan asli, sehingga belum mewakili kondisi lapangan.
Rencana perbaikan diurutkan berdasarkan penyebab, bukan berdasarkan angka. Untuk jenis biji, penambahan data dari domain pengguna lebih dulu, karena data latih sekarang didominasi studio. Untuk cacat, penambahan sampel kelas Broken dan penyesuaian bobot kelas. Untuk detektor, pengumpulan foto nampan asli agar evaluasi tidak lagi memakai data sintetis. Penyetelan hiperparameter diletakkan paling akhir karena bukan sumber masalah utama.
== 4.5 Masukan Pengguna
Pengujian dengan pengguna di luar tim belum dilakukan. Masukan yang tercatat berasal dari peninjauan internal: lima anggota tim mencoba alur aplikasi di luar perannya masing-masing, dan temuan yang disepakati dicatat di bawah. Masukan yang sudah ditindaklanjuti:
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 4.6 Masukan internal dan tindak lanjutnya]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.4217fr, 0.4578fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Masukan*],
    align(left)[*Tindak lanjut*],
    align(center)[*Status*],
  ),
  align(left)[Tombol tambah resep sulit ditemukan di header],
  align(left)[Dipindah menjadi tombol mengambang di katalog Seduh],
  align(center)[Selesai],
  align(left)[Riwayat tidak bisa dihapus sehingga daftar menumpuk],
  align(left)[Ditambah hapus dengan dialog konfirmasi, cacat dan rekomendasi ikut terhapus],
  align(center)[Selesai],
  align(left)[Kartu riwayat sulit dikenali tanpa gambar],
  align(left)[Ditambah thumbnail foto analisis],
  align(center)[Selesai],
  align(left)[Resep buatan sendiri butuh langkah dan video, bukan hanya angka],
  align(left)[Form langkah dinamis dan tautan video ditambahkan],
  align(center)[Selesai],
  align(left)[Metode seduh di luar daftar tidak bisa dicatat],
  align(left)[Ditambah pilihan metode Lainnya dengan nama bebas],
  align(center)[Selesai],
)
]
]
#v(6pt)
#v(8pt)
Pengujian dengan pengguna di luar tim dijadwalkan pada Minggu 14 sampai 15, dengan sasaran minimal tiga orang yang pernah menyeduh kopi manual.
== 4.6 Ketercapaian Kriteria Keberhasilan
Bagian ini ditulis pada laporan akhir.
= Bab 5. Pengelolaan Proyek dan Penutup
== 5.1 Rencana dan Realisasi
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 5.1 Rincian pekerjaan dan realisasi sampai Minggu 12]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.3976fr, 0.1928fr, 0.1807fr, 0.2289fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Tugas*],
    align(left)[*Penanggung jawab*],
    align(left)[*Rencana*],
    align(left)[*Realisasi sampai Minggu 12*],
  ),
  align(left)[Perencanaan proyek, pembagian peran, dan jadwal],
  align(left)[Shabran],
  align(left)[Minggu 1 sampai 2],
  align(left)[Selesai Minggu 2],
  align(left)[Proposal dan revisi sesuai rubrik],
  align(left)[Seluruh tim],
  align(left)[Minggu 1 sampai 3],
  align(left)[Selesai Minggu 3],
  align(left)[Dokumen kebutuhan, arsitektur, dan design system],
  align(left)[Seluruh tim],
  align(left)[Minggu 3 sampai 6],
  align(left)[Selesai Minggu 7],
  align(left)[Mockup antarmuka],
  align(left)[Shabran],
  align(left)[Minggu 4 sampai 6],
  align(left)[Selesai Minggu 7],
  align(left)[Skema basis data dan seeder knowledge base],
  align(left)[Ababil],
  align(left)[Minggu 5 sampai 7],
  align(left)[Selesai Minggu 8, dilanjutkan sampai skema v7 pada Minggu 12],
  align(left)[Fondasi aplikasi: struktur per fitur, Riverpod, GoRouter],
  align(left)[Sultan],
  align(left)[Minggu 5 sampai 7],
  align(left)[Selesai Minggu 8],
  align(left)[Implementasi tujuh layar],
  align(left)[Sultan, Shabran],
  align(left)[Minggu 6 sampai 9],
  align(left)[Selesai Minggu 12],
  align(left)[Registry dataset dan audit data],
  align(left)[Kevin],
  align(left)[Minggu 6 sampai 7],
  align(left)[Selesai Minggu 7],
  align(left)[Pelatihan dan evaluasi model sangrai],
  align(left)[Kevin],
  align(left)[Minggu 7 sampai 9],
  align(left)[Selesai Minggu 8, dilatih ulang Minggu 12],
  align(left)[Pelatihan model jenis, cacat, dan detektor],
  align(left)[Kevin],
  align(left)[Minggu 9 sampai 11],
  align(left)[Selesai Minggu 12],
  align(left)[Integrasi inferensi TFLite on-device],
  align(left)[Kevin, Sultan],
  align(left)[Minggu 9 sampai 10],
  align(left)[Selesai Minggu 12],
  align(left)[Rule engine skor kualitas],
  align(left)[Ababil],
  align(left)[Minggu 9 sampai 10],
  align(left)[Selesai Minggu 12],
  align(left)[Pengisian knowledge base 14 resep],
  align(left)[Ababil],
  align(left)[Minggu 9],
  align(left)[Selesai Minggu 12],
  align(left)[Riwayat, detail inspeksi, dan hapus dari SQLite],
  align(left)[Ababil, Sultan],
  align(left)[Minggu 10],
  align(left)[Selesai Minggu 12],
  align(left)[Resep buatan pengguna],
  align(left)[Shabran, Ababil],
  align(left)[Minggu 11],
  align(left)[Selesai Minggu 12],
  align(left)[Akun dan sinkronisasi antar perangkat],
  align(left)[Sultan, Ababil],
  align(left)[Minggu 11 sampai 12],
  align(left)[Sebagian, uji dua perangkat belum],
  align(left)[Ekspor CSV],
  align(left)[Ababil],
  align(left)[Minggu 10],
  align(left)[Belum, bergeser ke Minggu 13],
  align(left)[Rencana uji dan kasus uji],
  align(left)[Dino],
  align(left)[Minggu 7 sampai 8],
  align(left)[Selesai Minggu 8],
  align(left)[Eksekusi uji otomatis dan pencatatan bug],
  align(left)[Dino, Ababil],
  align(left)[Minggu 8 sampai 12],
  align(left)[278 uji lulus, 6 bug tercatat],
  align(left)[Analisis bentuk OpenCV],
  align(left)[Sultan],
  align(left)[Minggu 11],
  align(left)[Belum, bergeser ke Minggu 14],
  align(left)[Uji on-device dan pengukuran RAM],
  align(left)[Dino],
  align(left)[Minggu 12],
  align(left)[Latensi terukur di mesin pengembang, RAM belum],
  align(left)[Dokumen Milestone 2 dan Lampiran],
  align(left)[Seluruh tim],
  align(left)[Minggu 12],
  align(left)[Selesai Minggu 12],
)
]
]
#v(6pt)
#v(8pt)
Dari 22 butir pekerjaan, 18 selesai, satu sebagian, dan tiga bergeser ke Minggu 13 sampai 14. Keterlambatan terbesar ada pada integrasi model dan ekspor CSV. Integrasi model mundur sekitar dua minggu karena pelatihan harus diulang setelah ground truth berpindah ke hasil pelatihan yang benar-benar tereksekusi.
== 5.2 Kontribusi Anggota
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 5.2 Kontribusi anggota dan bagian saat demo]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.1928fr, 0.3735fr, 0.2530fr, 0.1084fr, 0.1928fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Nama*],
    align(left)[*Tugas selesai*],
    align(left)[*Bukti*],
    align(center)[*Estimasi kontribusi*],
    align(left)[*Bagian saat demo*],
  ),
  align(left)[Ahmad Kevin Malik Z],
  align(left)[Registry dataset, audit dan deduplikasi, pelatihan empat model, ekspor TFLite, pipeline inferensi on-device],
  align(left)[42 commit; folder inference 7 berkas; Lampiran F],
  align(center)[30%],
  align(left)[Alur inferensi dan hasil model],
  align(left)[Ghazwan Ababil],
  align(left)[Skema basis data v1 sampai v7, seeder knowledge base, 14 resep, rule engine, upload foto, sinkronisasi, sebagian besar pengujian otomatis],
  align(left)[60 commit, termasuk 31 commit pada folder uji],
  align(center)[28%],
  align(left)[Basis data, knowledge base, dan sinkronisasi],
  align(left)[Muhammad Shabran],
  align(left)[Design system, mockup enam layar, modul kamera, form resep pengguna, koordinasi jadwal],
  align(left)[4 commit; folder UI berisi enam mockup dan satu berkas design system],
  align(center)[15%],
  align(left)[Alur scan sampai hasil dan resep pengguna],
  align(left)[Handino Asa Galih R],
  align(left)[Rencana uji, 12 kasus uji manual, pencatatan bug, peninjauan hasil pengujian],
  align(left)[4 commit; dokumen kasus uji pada Lampiran E],
  align(center)[14%],
  align(left)[Kasus uji dan hasil pengujian],
  align(left)[Sultan Nashira A],
  align(left)[Fondasi aplikasi, navigasi GoRouter, Beranda dari SQLite, auth gate, layar login dan profil],
  align(left)[2 commit; app/router dan fitur auth],
  align(center)[13%],
  align(left)[Navigasi, akun, dan Beranda],
)
]
]
#v(6pt)
#v(8pt)
Estimasi kontribusi mengacu pada kesepakatan tim pada Milestone 1 dan belum diperbarui untuk Minggu 9 sampai 12. Jumlah commit dipakai sebagai bukti yang dapat diperiksa, bukan sebagai dasar penilaian tunggal, karena pekerjaan desain, pengujian, dan koordinasi tidak selalu menghasilkan commit.
== 5.3 Perubahan, Risiko, dan Permintaan Tambahan
Perubahan dari proposal beserta alasannya.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 5.3 Perubahan dari proposal]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.3855fr, 0.3855fr, 0.2289fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Perubahan*],
    align(left)[*Alasan*],
    align(left)[*Sudah dikonsultasikan*],
  ),
  align(left)[Ground truth model berpindah ke hasil pelatihan yang benar-benar tereksekusi],
  align(left)[Hasil eksperimen lama tidak dapat direproduksi dan berbeda arsitektur dari yang benar-benar dilatih],
  align(left)[Belum, perlu dilaporkan ke dosen Pemrograman Mesin],
  align(left)[Cacat disederhanakan dari enam kelas menjadi empat kelas],
  align(left)[Sampel untuk sebagian subkelas terlalu sedikit untuk dilatih terpisah],
  align(left)[Belum],
  align(left)[Model sangrai memakai empat kelas termasuk Green, bukan gerbang terpisah],
  align(left)[Green tetap dapat dikenali sebagai tingkat sangrai tanpa model tambahan],
  align(left)[Belum],
  align(left)[Ukuran model naik dari target 4 MB menjadi sekitar 17 MB],
  align(left)[Detektor dan tiga classifier fp32 lebih besar, tetapi kuantisasi INT8 menurunkan kesesuaian keluaran],
  align(left)[Belum],
  align(left)[Ditambah akun dan sinkronisasi riwayat ke cloud],
  align(left)[Permintaan agar riwayat tetap ada saat berganti perangkat],
  align(left)[Belum, tercatat pada catatan keputusan internal],
  align(left)[Foto diunggah best-effort ke Cloudinary],
  align(left)[Agar riwayat terbaca di perangkat lain; alur analisis tetap offline],
  align(left)[Belum],
  align(left)[Analisis bentuk belum memakai OpenCV],
  align(left)[Waktu pengembangan habis di integrasi model; sementara memakai geometri bounding box],
  align(left)[Belum],
)
]
]
#v(6pt)
#v(8pt)
Lima risiko terbesar untuk Minggu 13 sampai 16.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 5.4 Risiko utama Minggu 13 sampai 16]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.3253fr, 0.1325fr, 0.0964fr, 0.0964fr, 0.3494fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Risiko*],
    align(center)[*Kemungkinan*],
    align(center)[*Dampak*],
    align(center)[*Tingkat*],
    align(left)[*Tindakan*],
  ),
  align(left)[Akurasi jenis biji tetap rendah sehingga hasil sering menjadi Mixed],
  align(center)[Tinggi],
  align(center)[Tinggi],
  align(center)[Tinggi],
  align(left)[Tambah data latih dari domain pengguna pada Minggu 14; bila tetap rendah, tampilkan keterbatasan secara eksplisit],
  align(left)[Uji foto lapangan menunjukkan performa jauh di bawah angka uji],
  align(center)[Tinggi],
  align(center)[Tinggi],
  align(center)[Tinggi],
  align(left)[Uji 20 sampai 30 foto ponsel pada Minggu 13 sebelum menyusun klaim demo],
  align(left)[Ekspor CSV dan analisis OpenCV tidak selesai sebelum Demo Day],
  align(center)[Sedang],
  align(center)[Sedang],
  align(center)[Sedang],
  align(left)[Kerjakan CSV lebih dulu karena lebih kecil; OpenCV boleh dijadikan rencana lanjutan],
  align(left)[Sinkronisasi gagal saat diuji dua perangkat],
  align(center)[Sedang],
  align(center)[Sedang],
  align(center)[Sedang],
  align(left)[Uji dua perangkat pada Minggu 14; bila gagal, sajikan sebagai fitur dengan catatan keterbatasan],
  align(left)[Pengguna pengganti tidak cukup mewakili pengguna nyata],
  align(center)[Sedang],
  align(center)[Rendah],
  align(center)[Sedang],
  align(left)[Cari minimal tiga penyeduh kopi manual di luar tim pada Minggu 14 sampai 15],
)
]
]
#v(6pt)
#v(8pt)
Permintaan tambahan setelah proposal disetujui.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel 5.5 Permintaan tambahan dan keputusan tim]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.4337fr, 0.2289fr, 0.1325fr, 0.2048fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Permintaan*],
    align(left)[*Dari mata kuliah*],
    align(left)[*Waktu*],
    align(left)[*Keputusan tim*],
  ),
  align(left)[Akun pengguna dan riwayat yang tetap ada saat berganti perangkat],
  align(left)[Pemrograman Mobile],
  align(left)[Minggu 11],
  align(left)[Dikerjakan, selesai sebagian],
  align(left)[Resep buatan pengguna dengan langkah dan video],
  align(left)[Pemrograman Mobile],
  align(left)[Minggu 11],
  align(left)[Dikerjakan, selesai],
  align(left)[Lampiran khusus Pembelajaran Mesin dengan format tersendiri],
  align(left)[Pemrograman Mesin],
  align(left)[Minggu 12],
  align(left)[Dikerjakan, menjadi Lampiran D.1 dan Lampiran F],
)
]
]
#v(6pt)
== 5.4 Kesimpulan
Bagian ini ditulis pada laporan akhir.
== 5.5 Pelajaran dan Saran
Bagian ini ditulis pada laporan akhir.
= Lampiran A. Tangkapan Layar Fitur
Tangkapan layar diambil dari aplikasi yang berjalan pada perangkat Android.
#grid(columns: (1fr, 1fr), column-gutter: 1.2cm, align: center + horizon, align(center)[#image("assets/laporan/a-beranda.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.1 Layar Beranda]], align(center)[#image("assets/laporan/a-setup-scan.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.2 Layar Setup Scan]])
#v(10pt)
#grid(columns: (1fr, 1fr), column-gutter: 1.2cm, align: center + horizon, align(center)[#image("assets/laporan/a-scan.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.3 Layar Scan Kamera]], align(center)[#image("assets/laporan/a-detail-inspeksi.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.4 Layar Detail Inspeksi]])
#v(10pt)
#grid(columns: (1fr, 1fr), column-gutter: 1.2cm, align: center + horizon, align(center)[#image("assets/laporan/a-riwayat.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.5 Layar Riwayat Analisis]], align(center)[#image("assets/laporan/a-katalog.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.6 Layar Katalog Metode Seduh]])
#v(10pt)
#grid(columns: (1fr), column-gutter: 1.2cm, align: center + horizon, align(center)[#image("assets/laporan/a-detail-resep.png", width: 4.6cm)\ #text(size: 9pt)[Gambar A.7 Layar Detail Resep]])
#v(10pt)
= Lampiran B. Logbook Mingguan Minggu 1 sampai 12
#align(center)[#text(size: 9pt, weight: "bold")[Tabel B.1 Logbook mingguan Minggu 1 sampai 12]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0783fr, 0.3735fr, 0.1566fr, 0.1928fr, 0.1988fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*Minggu*],
    align(left)[*Pekerjaan selesai*],
    align(left)[*Dikerjakan oleh*],
    align(left)[*Kendala*],
    align(left)[*Rencana berikutnya*],
  ),
  align(center)[1],
  align(left)[Pembentukan tim, curah gagasan, penentuan topik],
  align(left)[Seluruh tim],
  align(left)[Belum ada lingkup],
  align(left)[Menyusun proposal],
  align(center)[2],
  align(left)[Penyusunan proposal: lingkup, peran, jadwal],
  align(left)[Seluruh tim],
  align(left)[Tidak ada],
  align(left)[Finalisasi proposal],
  align(center)[3],
  align(left)[Revisi proposal sesuai rubrik; repositori dibuat],
  align(left)[Sultan],
  align(left)[Tidak ada],
  align(left)[Menyusun dokumen kebutuhan],
  align(center)[4],
  align(left)[Draf PRD dan arsitektur],
  align(left)[Ababil, Kevin],
  align(left)[Belum ada acuan teknis],
  align(left)[Menyempurnakan arsitektur],
  align(center)[5],
  align(left)[Draf skema basis data],
  align(left)[Ababil],
  align(left)[Taksonomi cacat belum final],
  align(left)[Meninjau skema],
  align(center)[6],
  align(left)[Draf design system dan mockup],
  align(left)[Shabran],
  align(left)[Tidak ada],
  align(left)[Finalisasi mockup],
  align(center)[7],
  align(left)[Dokumen proyek selesai; audit dataset dan deduplikasi],
  align(left)[Ababil, Kevin],
  align(left)[Data uji duplikat data latih],
  align(left)[Melatih model dasar],
  align(center)[8],
  align(left)[Skema SQLite v1, struktur per fitur, tujuh layar, pelatihan model sangrai, evaluasi eksternal],
  align(left)[Seluruh tim],
  align(left)[Eksperimen pertama batal karena kebocoran data],
  align(left)[Integrasi inferensi],
  align(center)[9],
  align(left)[Tidak ada commit pada repositori],
  align(left)[Tidak tercatat],
  align(left)[Aktivitas tidak tercatat],
  align(left)[Melanjutkan pelatihan model],
  align(center)[10],
  align(left)[Tidak ada commit pada repositori],
  align(left)[Tidak tercatat],
  align(left)[Aktivitas tidak tercatat],
  align(left)[Melanjutkan pelatihan model],
  align(center)[11],
  align(left)[Tidak ada commit pada repositori],
  align(left)[Tidak tercatat],
  align(left)[Aktivitas tidak tercatat],
  align(left)[Integrasi basis data dan model],
  align(center)[12],
  align(left)[Skema v2 sampai v7, inferensi TFLite on-device, rule engine, 14 resep, riwayat dari basis data, resep pengguna, akun dan sinkronisasi, 278 uji otomatis, dokumen Milestone 2],
  align(left)[Seluruh tim],
  align(left)[Pelatihan ulang dan integrasi memakan waktu],
  align(left)[Minggu 13: ekspor CSV dan uji foto nyata],
)
]
]
#v(6pt)
#v(6pt)
Catatan: repositori tidak mencatat aktivitas pada Minggu 9 sampai 11. Entri tersebut perlu dilengkapi dari catatan masing-masing anggota sebelum dikumpulkan.
= Lampiran C. Dokumen Rujukan
#align(center)[#text(size: 9pt, weight: "bold")[Tabel C.1 Dokumen rujukan tim]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0723fr, 0.3012fr, 0.0964fr, 0.1446fr, 0.2048fr, 0.1807fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*No*],
    align(left)[*Dokumen*],
    align(center)[*Versi*],
    align(left)[*Pemilik*],
    align(left)[*Bagian yang merujuk*],
    align(left)[*Keterangan*],
  ),
  align(center)[1],
  align(left)[PRD (spesifikasi kebutuhan produk)],
  align(center)[1.0],
  align(left)[Seluruh tim],
  align(left)[Bab 1, Bab 2.1, Bab 4],
  align(left)[Kebutuhan fungsional, non-fungsional, kriteria penerimaan],
  align(center)[2],
  align(left)[Arsitektur mobile],
  align(center)[2.0],
  align(left)[Sultan],
  align(left)[Bab 2.2, Bab 3.2],
  align(left)[Struktur folder, route, alur data],
  align(center)[3],
  align(left)[Arsitektur machine learning],
  align(center)[2.0],
  align(left)[Kevin],
  align(left)[Bab 2.4, Bab 3.4, Lampiran F],
  align(left)[Pipeline model, pemetaan label, evaluasi],
  align(center)[4],
  align(left)[Skema basis data],
  align(center)[1.7],
  align(left)[Ababil],
  align(left)[Bab 2.3, Bab 3.3],
  align(left)[DDL, kamus data, migrasi],
  align(center)[5],
  align(left)[Design system],
  align(center)[1.0],
  align(left)[Shabran],
  align(left)[Bab 2.5],
  align(left)[Token warna, tipografi, komponen],
  align(center)[6],
  align(left)[Catatan keputusan proyek],
  align(center)[1.0],
  align(left)[Seluruh tim],
  align(left)[Bab 5.3],
  align(left)[Keputusan D-01 sampai D-30],
  align(center)[7],
  align(left)[Rencana dan kasus uji],
  align(center)[2.0],
  align(left)[Dino],
  align(left)[Bab 4],
  align(left)[Kasus uji dan hasil eksekusi],
  align(center)[8],
  align(left)[Lampiran Pembelajaran Mesin],
  align(center)[1.0],
  align(left)[Kevin],
  align(left)[Lampiran D.1, Lampiran F],
  align(left)[Dataset, praproses, eksperimen, evaluasi],
)
]
]
#v(6pt)
= Lampiran D. Dokumen Tambahan dari Dosen
Ada satu dokumen tambahan yang diumumkan dosen, yaitu laporan Pembelajaran Mesin dengan format tersendiri.
== D.1 Lampiran Pembelajaran Mesin
#align(center)[#text(size: 9pt, weight: "bold")[Tabel D.1 Dokumen tambahan]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2048fr, 0.3614fr, 0.3133fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Mata kuliah*],
    align(left)[*Dosen*],
    align(left)[*Dokumen*],
    align(left)[*Tanggal pengumuman*],
  ),
  align(left)[Pemrograman Mesin],
  align(left)[Rachmad Imam Tarecha, S.Kom., M.Kom.],
  align(left)[Lampiran D Pembelajaran Mesin (model M3 Roast)],
  align(left)[Minggu 12],
)
]
]
#v(6pt)
#v(6pt)
Isi teknis dokumen tersebut memuat dataset, praproses, eksperimen pembanding, dan evaluasi rinci. Isi yang sama disajikan pada Lampiran F agar tidak terjadi pengulangan; rujukan silang dari dokumen mata kuliah diarahkan ke sana.
= Lampiran E. Daftar Tautan Eksternal
#align(center)[#text(size: 9pt, weight: "bold")[Tabel E.1 Daftar tautan eksternal]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0602fr, 0.2771fr, 0.1446fr, 0.3976fr, 0.1205fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*No*],
    align(left)[*Keterangan*],
    align(left)[*Bagian*],
    align(left)[*Tautan*],
    align(left)[*Jenis akses*],
  ),
  align(center)[1],
  align(left)[Repositori kode, branch development],
  align(left)[S.5],
  align(left)[https://github.com/AhmadKevin000/roastmate\_app/tree/development],
  align(left)[Publik],
  align(center)[2],
  align(left)[Rilis aplikasi v1.0.0],
  align(left)[S.5],
  align(left)[https://github.com/AhmadKevin000/roastmate\_app/releases/tag/v1.0.0],
  align(left)[Publik],
  align(center)[3],
  align(left)[Video demonstrasi],
  align(left)[S.5],
  align(left)[https://drive.google.com/file/d/1BDkgIDwbbKtpx5LzLJLArQuZd7efgj49/view],
  align(left)[Siapa saja yang memiliki tautan],
  align(center)[4],
  align(left)[Dokumen dan kasus uji],
  align(left)[Bab 4],
  align(left)[https://docs.google.com/spreadsheets/d/1yPwoO9JL2Ae\_4jj9oeB9Od19GuYvOb\_SFZenFmhJIjw/edit?gid=1451597130\#gid=1451597130],
  align(left)[Siapa saja yang memiliki tautan],
  align(center)[5],
  align(left)[Dataset sangrai, Kaggle],
  align(left)[Lampiran F.1],
  align(left)[https://www.kaggle.com/datasets/gpiosenka/coffee-bean-dataset-resized-224-x-224],
  align(left)[Publik],
  align(center)[6],
  align(left)[Dataset Robusta dan Arabika, Roboflow],
  align(left)[Lampiran F.1],
  align(left)[https://universe.roboflow.com/tugas-akhir-8wmr1/kopi-robusta-dan-arabika],
  align(left)[Publik],
)
]
]
#v(6pt)
= Lampiran F. Dokumentasi Model Pembelajaran Mesin
== F.1 Dataset
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.1 Karakteristik dan pembagian dataset sangrai]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2048fr, 0.7952fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Hal*],
    align(left)[*Isi*],
  ),
  align(left)[Sumber dan lisensi],
  align(left)[Kaggle, gpiosenka/coffee-bean-dataset-resized-224-x-224, lisensi CC BY-SA 4.0. Dataset tambahan untuk uji domain lain: Roboflow, kopi-robusta-dan-arabika.],
  align(left)[Cara pelabelan],
  align(left)[Berlabel dari sumber, satu folder per kelas. Tim tidak melakukan anotasi ulang dan tidak menggabungkan label.],
  align(left)[Jumlah total],
  align(left)[1.600 gambar PNG 224x224 (151,3 MB); setelah deduplikasi MD5 menjadi 1.194 gambar unik.],
  align(left)[Pembagian data],
  align(left)[Latih 836, validasi 179, uji 179. Stratified dan group-aware dengan unit split group\_id, seed 42.],
)
]
]
#v(6pt)
#v(8pt)
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.2 Sebaran data per kelas]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2651fr, 0.1807fr, 0.1807fr, 0.1807fr, 0.1928fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Kelas*],
    align(center)[*Latih*],
    align(center)[*Validasi*],
    align(center)[*Uji*],
    align(center)[*Total (%)*],
  ),
  align(left)[Green],
  align(center)[209],
  align(center)[45],
  align(center)[45],
  align(center)[299 (25,0%)],
  align(left)[Light],
  align(center)[210],
  align(center)[45],
  align(center)[45],
  align(center)[300 (25,1%)],
  align(left)[Medium],
  align(center)[210],
  align(center)[45],
  align(center)[45],
  align(center)[300 (25,1%)],
  align(left)[Dark],
  align(center)[207],
  align(center)[44],
  align(center)[44],
  align(center)[295 (24,7%)],
  align(left)[Total],
  align(center)[836],
  align(center)[179],
  align(center)[179],
  align(center)[1.194 (100%)],
)
]
]
#v(6pt)
#align(center)[#image("assets/laporan/f-sampel.png", width: 15.0cm)]
#align(center)[#text(size: 9pt)[Gambar F.1 Contoh sampel dataset per kelas]]
#v(8pt)
Analisis Dataset
Sebaran kelas hampir sempurna seimbang, setiap kelas menyumbang 24,7 sampai 25,1 persen, sehingga ketidakseimbangan kelas bukan sumber masalah dan tidak ada pembobotan kelas pada model sangrai. Kualitas datanya yang bermasalah: audit MD5 menemukan 809 dari 1.600 berkas (50,6 persen) merupakan duplikat persis, dan seluruh 400 gambar pada folder uji asli punya kembaran byte-identik di folder latih. Kondisi itu membuat skor validasi dan uji pada data mentah mengukur daya hafal, bukan kemampuan generalisasi. Penanganannya deduplikasi MD5, dilanjutkan deduplikasi near-duplicate berbasis embedding ResNet-18 pada ambang cosine 0,95, lalu split group-aware agar satu kelompok kemiripan tidak pernah masuk dua split sekaligus.
== F.2 Praproses Data
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.3 Langkah praproses data]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0542fr, 0.2651fr, 0.2771fr, 0.2530fr, 0.1506fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*No*],
    align(left)[*Langkah*],
    align(left)[*Alasan*],
    align(left)[*Parameter*],
    align(left)[*Diterapkan pada*],
  ),
  align(center)[1],
  align(left)[Deduplikasi duplikat persis (MD5)],
  align(left)[Seluruh isi folder uji asli adalah duplikat byte-identik dari latih],
  align(left)[1.194 unik dari 1.600; 406 berkas dibuang],
  align(left)[Seluruh dataset, sebelum split],
  align(center)[2],
  align(left)[Deduplikasi near-duplicate berbasis embedding],
  align(left)[Mencegah foto kembar dari biji yang sama tersebar ke dua split],
  align(left)[ResNet-18 ImageNet tanpa fine-tune, cosine minimal 0,95 menjadi group\_id],
  align(left)[Seluruh dataset, sebelum split],
  align(center)[3],
  align(left)[Split group-aware dan stratified],
  align(left)[Satu kelompok kemiripan tidak boleh muncul di lebih dari satu split],
  align(left)[70/15/15, unit group\_id, seed 42],
  align(left)[Pembentukan latih, validasi, uji],
  align(center)[4],
  align(left)[Resize bilinear ke 224x224],
  align(left)[Menyamakan ukuran masukan dengan kontrak pelatihan],
  align(left)[224x224, bilinear, RGB],
  align(left)[Latih, validasi, uji, inferensi],
  align(center)[5],
  align(left)[Skala piksel 0 sampai 255 tanpa normalisasi],
  align(left)[Normalisasi ImageNet sudah berada di dalam model],
  align(left)[float32 0 sampai 255, layout NHWC],
  align(left)[Latih, validasi, uji, inferensi],
  align(center)[6],
  align(left)[Augmentasi geometri dan kecerahan terbatas],
  align(left)[Warna adalah ciri utama tingkat sangrai, sehingga hue dan saturasi tidak boleh berubah],
  align(left)[fliplr 0,5; rotasi maksimal 10 derajat; translate 0,1; scale 0,1; hsv\_h 0; hsv\_s 0; hsv\_v 0,2],
  align(left)[Hanya data latih],
  align(center)[7],
  align(left)[Kalibrasi kuantisasi dari data latih],
  align(left)[Data uji tidak boleh dipakai untuk pelatihan maupun kalibrasi],
  align(left)[200 gambar, seluruhnya dari split latih],
  align(left)[Ekspor INT8 pada eksperimen E2],
)
]
]
#v(6pt)
== F.3 Eksperimen Pembanding
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.4 Hasil eksperimen pembanding]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0542fr, 0.2651fr, 0.2651fr, 0.1325fr, 0.1928fr, 0.0904fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*ID*],
    align(left)[*Model dan konfigurasi*],
    align(left)[*Hiperparameter utama*],
    align(left)[*Metrik (latih)*],
    align(left)[*Metrik (validasi)*],
    align(center)[*Terpilih*],
  ),
  align(center)[E1],
  align(left)[YOLOv8n-cls pada data mentah tanpa deduplikasi],
  align(left)[224 px; batch 32; 50 epoch; augmentasi ringan],
  align(left)[Tidak dicatat],
  align(left)[Akurasi 1,0000, tidak valid karena kebocoran],
  align(center)[Tidak],
  align(center)[E2],
  align(left)[YOLOv8n-cls pada data ter-dedup, split group-aware],
  align(left)[224 px; batch 32; 100 epoch dengan early stop di epoch 17; seed 42],
  align(left)[Tidak dicatat],
  align(left)[Akurasi 1,0000; pada uji eksternal hanya 0,3392],
  align(center)[Tidak],
  align(center)[E3],
  align(left)[MobileNetV3-Small pada data ter-dedup, ekspor fp32],
  align(left)[224 px; bobot awal ImageNet; early stop di epoch 11],
  align(left)[Sekitar 0,94 dari kurva],
  align(left)[Sekitar 0,92; uji 0,9274],
  align(center)[Ya],
)
]
]
#v(6pt)
#align(center)[#image("assets/laporan/f-kurva-roast.png", width: 14.0cm)]
#align(center)[#text(size: 9pt)[Gambar F.2 Kurva loss dan akurasi model sangrai pada data latih dan validasi]]
#v(8pt)
Analisis Eksperimen
Perubahan yang paling berpengaruh adalah penghapusan kebocoran data, bukan arsitektur atau hiperparameter. Model E1 meraih akurasi 1,0000 pada data uji, tetapi hanya 0,3392 ketika diuji pada 283 foto Robusta dari sumber lain. Setelah deduplikasi, metrik dalam domain kembali tinggi karena datasetnya homogen, sehingga evaluasi eksternal menjadi pembeda utama. Model E3 dipilih karena memenuhi syarat produksi: akurasi uji 0,9274, kurva validasi berada di atas kurva latih pada sebagian besar epoch sehingga tidak ada indikasi overfitting, dan keluarannya dapat diekspor fp32 tanpa penurunan kesesuaian argmax seperti pada kuantisasi INT8.
#align(center)[#image("assets/laporan/f-kurva-detektor.png", width: 13.0cm)]
#align(center)[#text(size: 9pt)[Gambar F.3 Kurva mAP50 dan mAP50-95 detektor per epoch]]
#v(8pt)
== F.4 Evaluasi Rinci pada Data Uji
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.5 Metrik per kelas model sangrai pada data uji]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.2530fr, 0.1928fr, 0.1928fr, 0.1928fr, 0.1687fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Kelas*],
    align(center)[*Presisi*],
    align(center)[*Recall*],
    align(center)[*F1*],
    align(center)[*Jumlah data*],
  ),
  align(left)[Green],
  align(center)[0,9574],
  align(center)[1,0000],
  align(center)[0,9783],
  align(center)[45],
  align(left)[Light],
  align(center)[0,9773],
  align(center)[0,9556],
  align(center)[0,9663],
  align(center)[45],
  align(left)[Medium],
  align(center)[0,9714],
  align(center)[0,7556],
  align(center)[0,8500],
  align(center)[45],
  align(left)[Dark],
  align(center)[0,8302],
  align(center)[1,0000],
  align(center)[0,9072],
  align(center)[44],
  align(left)[Rata-rata makro],
  align(center)[0,9341],
  align(center)[0,9278],
  align(center)[0,9254],
  align(center)[179],
)
]
]
#v(6pt)
#align(center)[#image("assets/laporan/f-confusion.png", width: 11.0cm)]
#align(center)[#text(size: 9pt)[Gambar F.4 Confusion matrix model sangrai pada data uji]]
#v(8pt)
#v(4pt)
Angka pada Tabel F.5 berasal dari run pelatihan terbaru dengan 179 gambar uji, sedangkan Gambar F.4 berasal dari artefak model yang saat ini terpasang di aplikasi. Pola kesalahannya sama, yaitu Medium tertukar ke Dark, sehingga gambar tetap dipakai sebagai ilustrasi.
#align(center)[#text(size: 9pt, weight: "bold")[Tabel F.6 Contoh kesalahan prediksi]]
#v(2pt)
#text(size: 8.5pt)[
#align(center)[
#table(
  columns: (0.0542fr, 0.2410fr, 0.1928fr, 0.2048fr, 0.3072fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(center)[*No*],
    align(left)[*Data*],
    align(left)[*Label sebenarnya*],
    align(left)[*Prediksi*],
    align(left)[*Dugaan penyebab*],
  ),
  align(center)[1],
  align(left)[medium (188).png],
  align(left)[Medium],
  align(left)[Dark, keyakinan 0,95],
  align(left)[Model sangat yakin tetapi salah; kemungkinan label meragukan atau biji berada di batas Dark],
  align(center)[2],
  align(left)[medium (237).png],
  align(left)[Medium],
  align(left)[Dark, keyakinan 0,72],
  align(left)[Warna permukaan lebih gelap daripada Medium lain di kelas yang sama],
  align(center)[3],
  align(left)[medium (220).png],
  align(left)[Medium],
  align(left)[Light, keyakinan 0,68],
  align(left)[Kesalahan ke arah sebaliknya, menunjukkan kelas Medium diapit dua batas yang sama-sama tipis],
)
]
]
#v(6pt)
Analisis Hasil Evaluasi
Kelas terlemah adalah Medium dengan recall 0,7556: dari 45 biji Medium, 9 diprediksi Dark dan sisanya menyebar ke Light dan Green, sedangkan Green dan Dark hampir sempurna. Pola ini berkaitan dengan temuan di F.1, karena pada ambang kemiripan 0,94 sudah muncul pasangan lintas kelas Dark dan Medium, sehingga sebagian batas Medium ke Dark memang ambigu secara visual, bukan semata kesalahan model. Akurasi uji 0,9274 konsisten dengan akurasi validasi sekitar 0,92, jadi tidak ada indikasi overfitting, tetapi validasi dan uji sama-sama berasal dari domain studio yang identik dengan data latih sehingga angka ini belum mewakili foto pengguna.
== F.5 Kesimpulan Analisis
Sumber masalah utama model sangrai adalah data, bukan arsitektur atau praproses: setengah dataset berupa duplikat persis dan folder uji aslinya kembar byte-identik dengan folder latih, dan setelah kebocoran itu dihapus model hanya mencapai 0,3392 pada foto dari sumber lain. Praproses yang diterapkan sudah sesuai kontrak masukan 224 bilinear tanpa normalisasi tambahan, sedangkan arsitektur tidak menunjukkan overfitting karena akurasi validasi justru lebih tinggi daripada akurasi latih. Kesalahan yang tersisa terkonsentrasi pada batas Medium ke Dark dengan recall Medium 0,7556, batas yang memang ambigu pada dataset ini. Perbaikan karena itu harus berupa penambahan data dari domain pengguna, bukan penyetelan hiperparameter.
= Lampiran G. Dokumentasi Kueri Basis Data
Lampiran ini wajib untuk tim Semester 3 yang mengikuti Basis Data Lanjut. Tim ini berada di Semester 5 dan memakai SQLite di perangkat, sehingga lampiran ini tidak disertakan.
= Lampiran H. Deklarasi Penggunaan AI
#align(center)[#text(size: 9pt, weight: "bold")[Tabel H.1 Deklarasi penggunaan AI]]
#v(2pt)
#text(size: 9pt)[
#align(center)[
#table(
  columns: (0.3373fr, 0.2048fr, 0.4578fr),
  inset: 4pt,
  stroke: 0.4pt,
  table.header(
    align(left)[*Bagian*],
    align(left)[*Alat*],
    align(left)[*Tujuan*],
  ),
  align(left)[Struktur skrip pelatihan dan evaluasi model],
  align(left)[Asisten kode],
  align(left)[Saran struktur dan penamaan; dijalankan dan diperiksa tim],
  align(left)[Struktur aplikasi mobile dan pemisahan per fitur],
  align(left)[Asisten kode],
  align(left)[Saran pemisahan modul; ditinjau dan diuji tim],
  align(left)[Pipeline inferensi dan postprocess detektor],
  align(left)[Asisten kode],
  align(left)[Saran alur isolate dan pengolahan keluaran model; diverifikasi dengan uji nyata],
  align(left)[Skrip pengujian dan skenario uji],
  align(left)[Asisten kode],
  align(left)[Saran skenario; dijalankan dan hasilnya diperiksa tim],
  align(left)[Dokumen arsitektur dan laporan eksperimen],
  align(left)[Asisten penulisan],
  align(left)[Merapikan kalimat dan tabel; isi diverifikasi tim],
  align(left)[Penyusunan laporan Milestone 2 ini],
  align(left)[Asisten AI],
  align(left)[Menyusun draf dan merapikan tabel dari data repositori; angka dan klaim diverifikasi tim],
)
]
]
#v(6pt)
#v(8pt)
Seluruh anggota memahami bagian yang dibantu AI dan mampu menjelaskan hasilnya, termasuk alasan pemilihan model, rumus skor kualitas, dan alasan setiap keputusan teknis yang tercatat pada dokumen keputusan proyek.
