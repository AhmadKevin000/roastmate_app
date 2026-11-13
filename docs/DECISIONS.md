# ROASTMATE — DECISION LOG

Versi: 1.5
Tujuan: mencatat keputusan & penyelesaian kontradiksi antar dokumen, agar tidak muncul lagi.

---

## D-01 — Timer seduh interaktif OUT OF SCOPE

**Konteks:** `architecture_ml.md` §38/§40 menyatakan "Interactive brewing timer OUT OF SCOPE", tetapi mockup `Detail Resep.png` menampilkan HUD timer langkah-per-langkah dan `DESIGN.md` memuat komponen "Extraction Timer HUD".

**Keputusan:**

- **Timer seduh interaktif** (countdown, start/stop, sinkronisasi waktu) = **OUT OF SCOPE**.
- Halaman **Detail Resep tetap ada** sebagai **panduan langkah statis** (persiapan, blooming, penuangan, penyajian).
- Label target waktu (mis. `00:00–00:45`) adalah **informasi tekstual statis**, bukan timer berjalan.

**Dampak:**

- `DESIGN.md`: komponen "Extraction Timer HUD" dihapus → diganti "Brewing Step Guide".
- `PRD.md`: "panduan langkah seduh (statis)" in-scope; "timer interaktif" out-of-scope.
- `ARCHITECTURE_MOBILE.md`: tidak ada modul timer di `lib/`.

---

## D-02 — Taksonomi Quality disatukan

**Konteks:** Dokumen ML memakai `High/Medium/Low` (§19), contoh JSON memakai `medium_high` (§29), UI memakai grade `Specialty/Premium/Standard/Below Standard/Off Grade`.

**Keputusan:**

- **Quality Profile kanonik = 3 level: `High` · `Medium` · `Low`** (Title Case; lihat D-12).
- Contoh JSON diperbaiki dari `medium_high` → `High`.
- Grade tampilan dipetakan eksplisit dari profile:

| Quality Profile | Score  | Indicative Grade |
| --------------- | ------ | ---------------- |
| High            | 85–100 | Specialty        |
| High            | 75–84  | Premium          |
| Medium          | 60–74  | Standard         |
| Low             | 40–59  | Below Standard   |
| Low             | 0–39   | Off Grade        |

Ambang grade = parameter sistem, dapat dikonfigurasi.

---

## D-03 — Defect DS004 di luar taxonomy final

**Konteks:** DS004 punya kelas `burnt`, `mold`, `under` tanpa tujuan mapping, sementara taxonomy final hanya 6 kelas.

**Keputusan:** `burnt`, `mold`, `under` → **EXCLUDED** dari training taxonomy final.
`burnt` tidak otomatis dipetakan ke `scorched`.

Catatan: daftar kelas DS004 disempurnakan di **D-19** — `normal`→`healthy`; `insect`+`mold` sebenarnya satu kelas gabungan `insectOrMold`.

---

## D-04 — "Moisture predictions" dihapus

**Konteks:** `DESIGN.md` menyebut "moisture predictions", tetapi tidak ada model/sumber data kelembapan di arsitektur ML.

**Keputusan:** Hapus referensi moisture dari `DESIGN.md`. Tidak ada fitur prediksi kelembapan.

---

## D-05 — Target ukuran model ditandai perlu dikaji ulang

**Konteks:** Target "total model size ≤ ~4 MB" untuk 4 model YOLOv8n INT8 berisiko tidak realistis.

**Keputusan:** Pertahankan sebagai target awal, tetapi **tandai "perlu dikaji ulang"** setelah pengukuran nyata pasca-kuantisasi.

---

## D-06 — Grade banner dipetakan ke Quality Profile

**Konteks:** UI menampilkan grade indikatif; tidak ada jembatan resmi ke Quality Profile.

**Keputusan:** Grade banner diturunkan dari Quality Profile via tabel D-02. Satu sumber kebenaran: profile → grade.

---

## D-07 — Bobot Quality Engine default

**Konteks:** Dokumen ML hanya memberi `w1..w4` tanpa angka.

**Keputusan:** Gunakan bobot default berikut sebagai **parameter awal yang dapat dikonfigurasi** (bukan nilai final):

| Komponen | Bobot |
| -------- | ----- |
| defect   | 0.40  |
| shape    | 0.20  |
| size     | 0.20  |
| roast    | 0.20  |

---

## D-08 — Dokumen baru & backup

**Konteks:** `prd.md` identik dengan `architecture_ml.md`; `architecture_mobile.md` kosong; tidak ada PRD sungguhan.

**Keputusan:**

- Dokumen baru ditempatkan di `roastmate_app/docs/`.
- Dokumen lama di root (`prd.md`, `architecture_ml.md`, `architecture_mobile.md`, `DESIGN.md`) **tetap utuh sebagai backup**.
- Gaya dokumen arsitektur: flat, dominan tabel, maksimal 2 level, tanpa pengulangan.

---

## D-09 — URL sumber dataset diletakkan di ARCHITECTURE_ML, bukan PRD

**Konteks:** Versi compact `ARCHITECTURE_ML.md` menghilangkan URL dataset demi kerapian, padahal aturan provenance mewajibkan pencatatan sumber.

**Keputusan:**

- URL sumber dataset & brewing masuk ke **Lampiran A & B `ARCHITECTURE_ML.md`** (Opsi A).
- `PRD.md` tetap tanpa URL (hanya menyebut dataset secara kategoris).
- Jangka panjang, `dataset_registry.csv` menjadi sumber kebenaran tunggal URL mentah; lampiran cukup merujuk padanya (jalur Opsi B/C).

---

## D-10 — Konsistensi skema Knowledge Base

**Konteks:** Tiga versi skema saling bertabrakan. `ARCHITECTURE_ML.md` §10 menaruh `grind_size`, `water_volume_ml`, `temperature_c`, `brewing_time_s`, `source` di tabel metode **dan** resep. `ARCHITECTURE_MOBILE.md` §8 memakai `parameter` (blob) dan menaruh `rasio/waktu/grind/suhu` di metode.

**Keputusan:**

- Parameter seduh dimiliki **satu tabel saja: `brew_recipes`**. Tidak diduplikasi di `brew_methods`.
- `brew_methods` bersifat **deskriptif** (`method_id`, `method_name`, `method_type`, `description`).
- `brew_recipes` menyimpan `dose_g`, `water_volume_ml`, `grind_size`, `temperature_c`, `brewing_time_s`, `source`, `is_default`, `steps` (JSON).
- `dose_g` = berat kopi bubuk (gram); rasio **dihitung** (`water_volume_ml / dose_g`), tidak disimpan.
- Langkah penyajian disimpan sebagai **kolom JSON `steps`** di `brew_recipes` (hanya ditampilkan).
- Katalog metode menampilkan parameter dari resep `is_default = 1`.
- Skema kanonik awalnya ditulis di `ARCHITECTURE_ML.md` §10; sejak D-12 dipindah ke **`DATABASE_SCHEMA.md`**, dan `ARCHITECTURE_ML.md` §10 hanya merujuk.

---

## D-11 — Knowledge base disimpan di SQLite saja

**Konteks:** `ARCHITECTURE_MOBILE.md` §7 menyebut KB sebagai asset (JSON/SQLite), §8 menyebut SQLite — berpotensi duplikasi.

**Keputusan:**

- KB disimpan di **SQLite** dan di-seed sekali saat pertama dijalankan.
- Seed berasal dari bundel `assets/knowledge/brewing_knowledge.json` (JSON → SQLite), bukan file `.db` siap-pakai.
- Tidak ada KB berbentuk asset JSON yang dibaca saat runtime (JSON hanya dipakai sekali saat seeding).
- Asset runtime hanya berisi model `.tflite`.

---

## D-12 — Skema database disentralisasi ke satu dokumen

**Konteks:** Skema tabel tersebar sebagai prosa di `ARCHITECTURE_ML.md` §10 dan `ARCHITECTURE_MOBILE.md` §9, tanpa tipe data, constraint, index, atau DDL — berpotensi tidak konsisten.

**Keputusan:**

- Dibuat **`DATABASE_SCHEMA.md`** sebagai sumber kanonik: DDL, tipe, constraint, index, ER, enum, migrasi, dan format seed.
- `ARCHITECTURE_ML.md` §10 dan `ARCHITECTURE_MOBILE.md` §9 diringkas menjadi rujukan ke `DATABASE_SCHEMA.md`.
- **Strategi PK:** `TEXT` berkode (`M001`, `R001`) untuk knowledge base; `INTEGER AUTOINCREMENT` untuk tabel riwayat.
- **`grade` diturunkan** dari `quality_profile` saat tampil, **tidak disimpan**.
- Enum disimpan **Title Case** (`Arabica`, `High`, `Green`, …); `method_type` snake_case.
- Ditambah tabel **`meta`** (`schema_version`, `kb_version`).
- `roast_context` nilai sah: `Green`, `Light`, `Medium`, `Dark`, `Light/Medium`, `Medium/Dark`.

---

## D-13 — Penyeragaman casing & representasi species

**Konteks:** Audit Fokus A menemukan: (a) label defect di `ARCHITECTURE_ML.md` §3/§15 memakai snake_case (`insect_damage`) sementara enum DB/PRD memakai Title Case (`Insect Damage`); (b) `PRD.md` §8 menulis species `Mixed / Uncertain` sementara `DATABASE_SCHEMA.md` hanya mengizinkan `Mixed`.

**Keputusan:**

- **Dua lapisan casing yang sah:** label target _training_ = snake_case; enum yang disimpan di DB dan ditampilkan di UI = **Title Case**. Pemetaan eksplisit dicatat di `ARCHITECTURE_ML.md` §3.
- Result object (`ARCHITECTURE_ML.md` §15) memakai **Title Case** agar langsung cocok dengan `analysis_defects.defect_class`.
- **Species kanonik = `Arabica` · `Robusta` · `Mixed`.** `uncertain` adalah **status tampilan** (diturunkan dari confidence, lihat FR-09), bukan nilai species.
- Contoh metode diseragamkan di `ARCHITECTURE_ML.md` §10 & `DATABASE_SCHEMA.md` §4, termasuk `M005 Kopi Tubruk immersion`.

---

## D-14 — Penyelarasan kontrak hasil & gap Fokus B

**Konteks:** Audit Fokus B menemukan gap antara PRD/MOBILE dan skema: status `uncertain` tak punya tempat, bukti visual tak disimpan, komposisi Beranda tak punya sumber, `size_uniformity`/`dose_g`/distribusi tak ada di kontrak hasil, `meta` tak disebut di MOBILE, target ukuran model tak ada di NFR.

**Keputusan:**

- **`status` (`OK`/`Uncertain`)** diturunkan saat tampil dari `roast_confidence` vs ambang; **tidak disimpan** (lihat D-15).
- **Bukti visual:** `analyses` menyimpan `annotated_image_path` (overlay bounding box dibakar saat analisis). Zoom = zoom gambar.
- **Komposisi Beranda:** `analyses` menyimpan `roast_distribution` (JSON agregat batch), sejalan dengan ML §7. Komposisi species dihitung dari `species` dominan per analisis (lihat D-15).
- **Kontrak hasil dilengkapi:** `size_uniformity`, `roast_distribution`, `status`, dan `dose_g` (pada recommendation).
- **`meta`** didaftarkan di `ARCHITECTURE_MOBILE.md` §9.
- **Target ukuran model** (≤ ~4 MB, perlu dikaji ulang) ditambahkan ke NFR `PRD.md` §7.
- Teks `reason` contoh diseragamkan ke Bahasa Indonesia (Bahasa UI).

---

## D-15 — Species tanpa sebaran & confidence

**Konteks:** `analyses` menyimpan `species_distribution` (JSON sebaran per biji) dan `species_confidence`; UI menampilkan rincian sebaran jenis biji yang tidak diperlukan. Permintaan: cukup jenis biji kopi saja.

**Keputusan:**

- `analyses` **hanya** menyimpan `species` = **satu jenis biji dominan** (`Arabica` · `Robusta` · `Mixed`).
- Kolom **`species_distribution`** dan **`species_confidence`** **dihapus**.
- Tidak ada tampilan persentase sebaran jenis biji di UI.
- Status `uncertain` kini diturunkan **hanya dari `roast_confidence`** vs ambang.
- **`roast_distribution` tetap** disimpan (di luar cakupan permintaan ini).
- Komposisi Beranda dihitung dari **hitungan `species` dominan per analisis**, bukan sebaran per biji.
- Menggantikan bagian terkait species pada D-14.

---

## D-16 — Nama metrik kanonik `visible_beans`

**Konteks:** Audit konsistensi menemukan satu metrik yang sama ditulis tiga ragam: `visible_bean_count` (`ARCHITECTURE_ML.md` §7), `visible_beans` (result object §15 & kolom DB), `visibleBeanCount` (`ARCHITECTURE_MOBILE.md` §12).

**Keputusan:**

- Nama kanonik = **`visible_beans`** (snake_case di DB & result object).
- `ARCHITECTURE_ML.md` §7 dan `ARCHITECTURE_MOBILE.md` §12 mengikuti.
- Penamaan domain Dart boleh camelCase (`visibleBeans`).

---

## D-17 — Penegakan enum via CHECK & filter `Mixed`

**Konteks:** Audit menutup dua gap terakhir: (a) `CHECK` constraint hanya ada di `brew_recipes`, sehingga kolom enum riwayat tidak ditegakkan; (b) filter riwayat di PRD §4 hanya "Semua / Arabica / Robusta" padahal `Mixed` adalah species sah.

**Keputusan:**

- Tambah **`CHECK`** pada seluruh kolom enum yang disimpan:
  - `brew_recipes`: `species`, `quality_profile`, `roast_context`, `grind_size`.
  - `analyses`: `species`, `roast`, `quality_profile`.
  - `analysis_defects`: `defect_class`.
- Filter riwayat **dan** komposisi Beranda menyertakan `Mixed` (`Semua / Arabica / Robusta / Mixed`).

---

## D-18 — Perluasan field knowledge base dari riset sumber

**Konteks:** Penelusuran sumber KB (BR001 andmos/Coffee, BR002 BrewSpec, BR003 Coffee Master, BR004 afrians19) menunjukkan field yang tersedia pada resep namun belum tertampung di skema.

**Keputusan:**

- Tambah kolom **`notes`** (`brew_recipes`) untuk tips kalibrasi rasa & catatan resep (mendukung PRD FR-07).
- Setiap item `steps` JSON diberi **`phase`**: `prep` (persiapan & alat) atau `brew` (langkah seduh) — mengikuti pemisahan "Preparation" vs "Step-by-step" pada BR003.
- **`method_type`** ditambah `espresso` → `pour_over` · `immersion` · `hybrid` · `pressure` · `espresso`.
- **`grind_size`** ditambah `Espresso` → `Espresso` · `Fine` · `Medium-Fine` · `Medium` · `Medium-Coarse` · `Coarse`.
- Satuan air **tetap** `water_volume_ml` (tidak diganti ke gram).
- **Di luar cakupan:**
  - `variant_name` — fokus pada **resep umum** per metode; peran ini diwakili `is_default = 1`.
  - `author` — atribusi cukup melalui **`source`** (BR001–BR004).
  - `result`/`ratings` (BrewSpec) dan seluruh log **Dial-in** (BR004) — itu hasil _penyeduhan_ pengguna (brew logger), bukan bagian grading biji. Tidak disimpan.

---

## D-19 — Penyelarasan dataset hasil verifikasi (Roboflow MCP + sumber asli)

**Konteks:** Verifikasi DS004–DS009 (12 Okt 2026) menemukan:
(a) DS004 memuat kelas **`normal`** (1.311, kelas terbesar) yang tidak tercatat, dan `insect`+`mold` sebenarnya satu kelas gabungan **`insectOrMold`** (45 insect + 2 mold);
(b) DS007 bertipe **instance-segmentation**, bukan detection;
(c) DS008 punya **17 kelas**, dokumen hanya memetakan 5;
(d) DS008 & DS009 bertaksonomi identik namun **ID gambar tidak beririsan** (561 vs 800 sampel → 0 irisan);
(e) model Defect §5 mencampur biji **mentah** (DS008/DS009) dan **sangrai** (DS004/DS007).

**Keputusan:**

- **Model Defect difokuskan biji SANGRAI (roasted-only): DS004 + DS007.** DS008/DS009 tidak dipakai untuk classifier Defect → menghapus mismatch domain (e). `insect_damage` tetap valid karena kerusakan struktural (lubang) tetap terlihat setelah disangrai.
- **DS004 diperbaiki** (menggantikan daftar kelas yang keliru di §2/§3): `normal`→`healthy`, `quaker`→`quaker`, `frag`→`broken`, `insect` (⊂ `insectOrMold`)→`insect_damage`; `mold`, `burnt`, `under`→EXCLUDED.
- **`Foreign Matter` dikecualikan** dari training (tidak ada sumber roasted). Enum DB tetap 6 nilai.
- **Kelas ekstra = kandidat fitur (Opsi A).** Kelas di luar 6 kelas final dicatat dan berpotensi menjadi fitur batch-level (mis. `husk_rate`, `immature_rate`); kelas bermakna setara di-grouping lebih dulu.
- **DS009 = sumber bentuk (Opsi A).** Mask instance-segmentation dipakai offline untuk kalibrasi `circularity`/`solidity` (OpenCV) dan validasi `shape_uniformity`/`size_uniformity`; bukan training model.
- **DS008 + DS009 boleh digabung** dengan **group-aware split by-source**.
- **Tidak ada perubahan skema DB:** enum `defect_class` tetap 6 nilai. → **DIREVISI oleh D-22** (defect menjadi biner; ada perubahan skema v1→v2).

**Dampak:**

- `ARCHITECTURE_ML.md` §2 (tabel + catatan bias), §3 (mapping + inventaris 17 kelas + kandidat fitur), §5 (Defect roasted-only), Lampiran A (snapshot verifikasi).

---

## D-20 — Dokumen = arsitektur target; kode direfaktor menyesuaikan

**Konteks:** `ARCHITECTURE_MOBILE.md` menetapkan struktur target (GoRouter, `app/`, `engines/`, `inference/`, `shared/`, `features/<f>/{presentation,domain,data}`, `features/scan/`), sementara kode masih memakai `MainPage` + `Navigator.push` dan `lib/pages/`. Selisih ini adalah **utang refactor**, bukan inkonsistensi dokumen.

**Keputusan:**

- Dokumen (`ARCHITECTURE_MOBILE.md`) adalah **arsitektur target**; kode akan direfaktor menyesuaikan, bukan sebaliknya.
- Target: GoRouter (bukan `MainPage`/`Navigator.push`); folder `app/`, `engines/`, `inference/`, `shared/`, `features/<f>/{presentation,domain,data}`; `features/scan/` (bukan `camera/`); `lib/pages/` legacy dihapus.

**Status:** **telah dieksekusi** — GoRouter diadopsi, `lib/pages/` dihapus, struktur folder target dibuat (`app/router`, `engines/`, `inference/`, `shared/`, `features/{home,scan,result,analysis,brew}`).

**Dampak:** `ARCHITECTURE_MOBILE.md` §2 (Tech Stack), §3 (Struktur Folder), §6 (Navigasi & Routes), §7 (Camera & ML Inference), §12 (Result Data Model).

---

## D-21 — Narasi hasil = template lokal (Opsi A)

**Konteks:** PRD FR-04 mewajibkan "narasi ringkas hasil", tetapi tidak ada komponen yang ditunjuk untuk menghasilkannya; `summaryText` di kode masih hardcoded di mock. Pertanyaan: apakah narasi berasal dari brewing knowledge base?

**Keputusan:**

- Narasi (`summaryText`, `reason`) dihasilkan **template lokal dari angka hasil** — **bukan** brewing knowledge base, **bukan** LLM.
- **`summaryText` tidak disimpan** (diturunkan saat tampil, seperti `grade`/`status`). `reason` tetap disimpan di `recommendations.reason`.
- Definisi di `ARCHITECTURE_ML.md` §16 "Narrative Generation" (satu seksi menangani keduanya).
- Bahasa **Indonesia** saja (selaras D-14).

**Dampak:** `ARCHITECTURE_ML.md` §16 (baru), §16→§17; `ARCHITECTURE_MOBILE.md` §12.
**Implementasi:** belum ada — `summaryText` masih hardcoded di mock.

---

## D-22 — Model Defect disederhanakan menjadi BINER (`Healthy` / `Defect`) — **DIBATALKAN oleh D-27**

**Konteks:** D-19 menetapkan taksonomi Defect 6 kelas, tetapi setelah penelusuran sumber roasted-only (DS004 + DS007):
(a) DS004 (setelah perbaikan D-19) hanya menyediakan `healthy`, `quaker`, `broken`, `insect_damage` — `scorched`/`foreign_matter` tanpa sumber roasted;
(b) `Foreign Matter` (benda asing) secara definisi **bukan biji**, sehingga tidak masuk akal sebagai kelas _classifier per biji_;
(c) sub-jenis defect pada satu foto batch (biji tampak dari atas) sulit dipisahkan secara andal dan tidak menambah nilai produk (yang dibutuhkan hanyalah **defect rate** dan kontribusinya ke quality score);
(d) distribusi DS004 setelah perbaikan hampir seimbang (`healthy` 1.311 vs total defect 1.475), sehingga masalah ketidakseimbangan kelas hilang.

**Keputusan:**

- Model Defect = **biner**: **`Healthy` · `Defect`**.
- Semua penyimpangan pada biji sangrai (pecah, serangan serangga, quaker, gosong, dll.) → **`Defect`**.
- **`Foreign Matter` ditangani oleh detector**, bukan classifier defect (bukan biji → tidak diprediksi per biji).
- **`Green` ditangani gate status** (D-23), bukan defect.
- `analysis_defects.defect_class` `CHECK` menjadi 2 nilai → **wajib migrasi skema v1→v2** (lihat `DATABASE_SCHEMA.md` §12).
- Menggantikan bagian enum 6-nilai Defect pada **D-19** (butir "Tidak ada perubahan skema DB") dan daftar kelas pada **D-03**/**D-13**.

**Dampak:** `PRD.md` §1, §8, FR-03/FR-04; `DATABASE_SCHEMA.md` §7, §11, §12; `ARCHITECTURE_ML.md` §3, §5, §13; `ml/registries/dataset_registry.csv`.

---

## D-23 — `Green` = gerbang status (G0); model Roast = 3 kelas — **DIBATALKAN oleh D-27**

**Konteks:** PRD FR-08 memperlakukan `Green` sebagai **status** ("roasting diperlukan, tanpa parameter seduh normal"), bukan tingkat roast. Secara empiris batas tersulit adalah **Light↔Medium** (DS011: recall `Medium` = 0.0000 pada EXP-005). Menjadikan `Green` kelas ke-4 roast classifier memperbesar ruang keputusan dan menggeser fokus dari batas tersulit.

**Keputusan:**

- `Green` = **status/gerbang (G0)** yang dievaluasi **sebelum** roast classifier dijalankan.
- Model Roast = **3 kelas**: **`Light` · `Medium` · `Dark`**.
- Implementasi: **B2 — shared backbone multi-head** (head "Green vs roasted" + head roast 3 kelas) sebagai opsi utama; **B3 — aturan warna (hue)** sebagai fallback 0 MB.
- `analyses.roast` **tetap** boleh menyimpan nilai `Green` (nilai _state_), sehingga skema kolom ini tidak berubah.
- FR-08 diperbarui: gate Green dijelaskan sebagai tahap sebelum klasifikasi roast.

**Dampak:** `PRD.md` §1, §8, FR-03, FR-08; `ARCHITECTURE_ML.md` §2, §3, §5.

---

## D-24 — Split grup-aware: near-dup **dan** seri sumber

**Konteks:** audit F1 (2026-10-15) menemukan dua bentuk kebocoran yang tidak
tertangkap oleh split acak:

1. **DS003** — 403 grup duplikat persis; **semua 400 gambar test punya kembar
   persis di train**. Akurasi 1,0 pada split bawaan adalah artefak.
2. **DS004** — kelas ditentukan penuh oleh **11 seri sumber**
   (`origin_country` × `variety` × `processing_method`); **setiap seri 100% satu
   label**. Near-dup berbasis piksel hanya menemukan 33 grup, tetapi seluruh
   foto satu seri berbagi satu label → split acak mempelajari seri, bukan defect.
   Ini juga menjelaskan G-DATA-3 DS004 (latar-saja 0,6935 vs baseline 0,5294).

**Keputusan:**

- Split **wajib grup-aware** pada dua level: `group_id` (near-dup) **dan**
  `source_group` (seri sumber semantik), mana yang lebih kasar.
- Manifest kanonik menambah kolom **`source_group`** (gabungan kolom metadata
  sumber; = `group_id` bila metadata tidak ada).
- `make_split.py` menambah opsi **`--group-col`** (default `group_id`; pakai
  `source_group` untuk DS004).
- `make_split.py` greedy diubah menjadi **stratified per kelas + seed satu grup
  per split** — target global membuat kelas minoritas habis di train sehingga
  val/test kosong.
- Artefak: `ml/registries/DS003_split.csv` (837/179/178) dan
  `ml/registries/DS004_split.csv` (1.620/771/395; **0 seri lintas split**).

**Konsekuensi yang diterima:** karena hanya ada 11 seri DS004, rasio tepat
70/15/15 **tidak mungkin**; hasil 58/28/14 dengan setiap kelas hadir di ketiga
split. F6 (M4) harus melaporkan **dua angka**: in-domain (split acak, pembanding)
dan **lintas-seri** (angka jujur).

**Dampak:** `ARCHITECTURE_ML.md` §2 (hasil audit F1); `ml/registries/MANIFEST_FORMAT.md`
(aturan 5); `ml/scripts/{audit,make_split}.py`; `ml/reports/F1-AUDIT.md` §2.2–2.3.

---

## D-25 — Dataset hanya dari sumber ter-host (Roboflow/Kaggle), bukan disk lokal

**Konteks (2026-10-15):** gambar DS006 404 di `source.roboflow.com` membuktikan
sumber publik bisa hilang kapan saja; disk lokal terbatas (~10 GiB) sementara
training berjalan di Kaggle (runtime terpisah). Kedelapan sumber Roboflow kini
sudah **di-fork ke workspace `ghazwan-ababil`** sehingga ter-host permanen.

**Keputusan:**

- **Sumber kebenaran dataset = Roboflow** (fork di workspace `ghazwan-ababil`)
  dan/atau Kaggle Dataset. Fork permanen → gambar selalu dapat diekspor ulang.
- **Tidak ada salinan gambar/anotasi lokal sebagai sumber pipeline.**
  `ml/data/raw` dan `ml/data/exports` dihapus; yang tetap di repo hanya teks
  kecil (registries, manifest, split CSV, laporan).
- **Notebook Kaggle self-contained**: menarik data saat **runtime** dari link
  export Roboflow (`https://app.roboflow.com/ds/<id>?key=<key>`, publik tanpa
  auth), lalu menjalankan split grup-aware + kontrak crop (`preprocess.py`)
  **di dalam notebook**.
- `enable_internet: true` wajib pada kernel.
- Peta fork & link export dicatat di `ml/registries/roboflow_forks.csv` dan
  `ml/registries/roboflow_exports.csv` (menggantikan ketergantungan pada
  `source.roboflow.com/<owner>/<id>/original.jpg` yang rapuh).
- Ekspor Roboflow dibuat **tanpa preprocessing & tanpa augmentation** — crop,
  kanvas abu, dan normalisasi tetap dijalankan `preprocess.py` (patuh aturan
  no-color-augmentation).

**Dampak:** `ml/README.md` (alur data); `ml/data/` (hanya teks); notebook F2+.

---

## D-26 — Latar BUKAN batasan ketat pada evaluasi deteksi

**Konteks (2026-10-15):** G-DET-3 dievaluasi di DS011 yang latarnya biru, sehingga
muncul pertanyaan apakah latar perlu dikontrol/di-_gate_.

**Keputusan:**

- Untuk **deteksi (M1)**, latar **tidak** dijadikan variabel yang dikontrol atau
  di-_gate_. Evaluasi memakai **frame alami apa adanya** — ini justru merepresentasikan
  kondisi deploy (meja, tangan, kantong, dsb).
- **Tidak ada ablasi latar** untuk detektor.
- Kontrak crop (`mask_bg` → kanvas abu) **tidak berlaku untuk detektor**: masking
  butuh lokasi biji → butuh detektor → sirkular. Detektor menerima frame penuh.
- **Terpisah:** untuk **klasifikasi**, kebocoran latar tetap ditangani `mask_bg=True`
  (temuan F1: latar mengkodekan kelas; `crop` saja tidak cukup). D-26 **tidak**
  melonggarkan aturan itu.

**Konsekuensi:** G-DET-3 tidak dapat diukur pada DS011 karena **tidak ada GT bbox**
(bukan karena latarnya). Diagnosa v2 menunjukkan recall 0,11 adalah **artefak
penyebut** (watershed over-segmentasi ~2×; detektor keluarkan ~6 box vs pseudo-GT 12;
recall datar saat `conf` disapu). Perlu definisi G-DET-3 yang ber-GT.

**Dampak:** `ml/reports/F2-DETECTOR.md`; plan v3 (Status F2).

---

## D-27 — Ground truth berpindah ke hasil training `ML_PBL` (membatalkan D-22 & D-23)

**Konteks:** Training & inference **yang benar-benar tereksekusi** ada di `ML_PBL/ml/`
(`models/metrics.json`, `models/labels.json`, `models/PREPROCESS.md`, `config.py`,
`kaggle/pipeline.py`, `scripts/predict.py`). Hasilnya berbeda dari lineage lama di
`roastmate_app/ml/` yang mendasari D-22/D-23 (defect biner, Green gate): arsitektur
yang terlatih = **MobileNetV3-Small** (classifier) + **YOLOv8n** (detector), bukan
YOLOv8n-cls.

**Keputusan (reversal):**

1. **D-22 dibatalkan** — Defect = **4 kelas** (`Normal` / `Quaker` / `Broken` / `Severe`).
   Skema `merged4` (6 raw → 4) mengungguli `raw6` dan biner. Severity weight:
   Normal 0.0 · Quaker 0.7 · Broken 0.3 · Severe 1.0. `analysis_defects.defect_class`
   `CHECK` = 4 nilai; **tidak ada migrasi** (`kSchemaVersion` = 1).
   - Sub-jenis parah (`under`/`burnt`/`insectOrMold`) digabung ke `Severe`;
     pembedanya **nilai turunan** `defect_interpretation` dari `Severe`+`roast`
     (`underdeveloped`/`overroasted`/`contamination`), bukan kolom DB.
2. **D-23 dibatalkan** — `Green` = **kelas roast ke-4** (roast = `Green`/`Light`/`Medium`/`Dark`),
   bukan gerbang G0. Tidak ada model `green_gate` terpisah.
3. **Species = 3 kelas** (`Arabica` / `Liberika` / `Robusta`) + `Mixed`.
   Kolom `Liberika` dibuang saat inference → A/R direnormalisasi; gate **0.70** → `Mixed`.
4. **Export:** classifier hanya **fp32** (INT8 ditolak — argmax-agreement < 1.0);
   detector fp16 default (ada fp32/int8). **Ukuran total ~17 MB** → supersede D-05
   (target "≤ ~4 MB" resmi dicabut).
5. **Quality score = defect-only** (`100 × (1 − defect_rate)`), ambang profile
   High ≥ 90 / Medium ≥ 70 / Low < 70. Uniformity tetap dihitung & ditampilkan,
   tapi tidak masuk rumus → **supersede D-07** (bobot 4-komponen default).
6. **Ambang confidence `uncertain` kini pasti:** species 0.70 · roast 0.45
   → menutup catatan terbuka "angka pasti belum ditetapkan".

**Dampak:** `PRD.md` §1/§6/§8/§9/NFR; `ARCHITECTURE_ML.md` §1–§5/§7–§9/§12–§15;
`DATABASE_SCHEMA.md` §5–§7/§11/§12/§15; `ARCHITECTURE_MOBILE.md` §2/§7/§8/§12/§16;
`DESIGN.md` (token & pemetaan defect).

---

## D-20 — Riwayat tanpa overlay per-biji & alternatif rekomendasi tunggal

**Konteks:** Penyelarasan skema dengan fitur Riwayat Analisis: mock riwayat menyimpan deteksi per-biji (bounding box + confidence) dan daftar alternatif rekomendasi (N item), sementara skema tidak menampung keduanya. Konfirmasi UI (Ghazwan): riwayat cukup menampilkan foto asli + rekap jumlah per kelas defect.

**Keputusan:**

- **Deteksi per-biji TIDAK disimpan** (tabel `analysis_detections` tidak dibuat). Overlay interaktif hanya ada pada layar hasil analisis langsung; Riwayat menampilkan foto asli (`image_path`) + rekap dari `analysis_defects`.
- Menyempurnakan D-14: `annotated_image_path` tetap ada di skema namun **boleh kosong**; bukti visual riwayat cukup `image_path`.
- **Rekomendasi alternatif maksimal 1** — skema `recommendations` (satu `alternative_method_id`) tidak berubah; UI membatasi satu alternatif.
- Tambah kolom `analyses`: **`batch_label`** (label pendek, mis. `Batch #042`), **`batch_name`** (nama batch, mis. `Mandheling Honey Anaerob`), **`model_version`** (provenance model, mis. `Model CV v2.4`). Skema naik ke **versi 2** dengan migrasi `ALTER TABLE`.

---

## D-20 — `analyses.name` untuk label batch

**Konteks:** Form scan setup meminta pengguna memberi nama batch (`batchName` di UI), dan nama itu dipakai judul kartu Beranda serta daftar riwayat. Skema `analyses` tidak punya kolom penyimpan nama, sehingga riwayat berbasis SQLite tidak bisa menampilkan nama batch.

**Keputusan:**

- Tambah kolom **`name TEXT`** (nullable) pada `analyses`.
- Kolom ini **hanya label tampilan**; tidak dipakai untuk perhitungan quality score, defect rate, atau rekomendasi.
- Baris lama tanpa nama ditampilkan sebagai `Batch tanpa nama`.
- `kSchemaVersion` naik **1 → 2** dengan migrasi `ALTER TABLE analyses ADD COLUMN name TEXT`.

**Dampak:** `DATABASE_SCHEMA.md` §6 & §12; `mobile/lib/core/database/schema.dart`; migrasi di `app_database.dart`.

---

## Catatan terbuka (belum diputuskan)

- ~~Ambang confidence untuk status `uncertain` (angka pasti belum ditetapkan)~~ → **selesai (D-27)**: species 0.70 · roast 0.45.
- Ambang deteksi "mixed batch" (jarak distribusi).
- ~~Validasi angka bobot quality engine terhadap data nyata~~ → **supersede (D-27)**: score defect-only, tanpa bobot w1..w4.
- ~~`Foreign Matter` tanpa sumber roasted~~ → **selesai (D-22)**: ditangani detector, bukan classifier.
- ~~Cakupan roast untuk robusta hijau (gap DS006 tanpa kelas `Green`)~~ → **selesai (D-23)**: `Green` = gerbang status, bukan kelas roast.
- Spot-check pelabelan DS007 (satu sampel `Scorched` tampak pucat seperti quaker/immature) — historis; DS007 tak dipakai di `ML_PBL` (lihat D-27).
- Implementasi `NarrativeGenerator` (D-21) belum ada — `summaryText` masih hardcoded di mock.
- Refaktor kode mobile menyesuaikan **D-27** (enum `DefectClass` 4 kelas `Normal/Quaker/Broken/Severe`, species +`Liberika`, `kSchemaVersion` = 1) — `schema.dart` sudah divergen sesuai D-27; refactor kode lain belum diimplementasi.
- Kalibrasi ambang per-sumber (per-source threshold) untuk detector/classifier belum ditetapkan.
- **DS006 — SELESAI (2026-10-15):** di-fork ke `ghazwan-ababil/kopi-robusta-dan-arabika-c7glg`
  (583 gambar, 6 kelas, 407/116/60); gambar ter-host ulang & dapat diunduh (HTTP 200).
  F5 (M3 roast) & F7 (M2 species) kembali dapat dijalankan.
- **DS009 — SELESAI (2026-10-15):** di-fork ke
  `ghazwan-ababil/coffee-beans-dataset-2-segmentation-hhd21` (6.331 gambar, 17 kelas,
  4432/1268/631) → sumber kalibrasi bentuk F3 tersedia kembali.
- **DS010 (blocker F1):** 0 gambar → F9 (validasi foto nyata) masih tidak dapat dijalankan.
- **M2 Species pasca-F1:** normalisasi warna perlu ditinjau ulang — selisih kecerahan Arabica/Robusta kolaps setelah kontrak crop (118,5 vs 115,3), jadi sinyal bentuk/tekstur lebih relevan (lihat `ml/audit/CROSS_SOURCE.md`).
