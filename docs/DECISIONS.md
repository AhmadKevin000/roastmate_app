# ROASTMATE — DECISION LOG

Versi: 1.0
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

| Quality Profile | Score | Indicative Grade |
|---|---|---|
| High | 85–100 | Specialty |
| High | 75–84 | Premium |
| Medium | 60–74 | Standard |
| Low | 40–59 | Below Standard |
| Low | 0–39 | Off Grade |

Ambang grade = parameter sistem, dapat dikonfigurasi.

---

## D-03 — Defect DS004 di luar taxonomy final

**Konteks:** DS004 punya kelas `burnt`, `mold`, `under` tanpa tujuan mapping, sementara taxonomy final hanya 6 kelas.

**Keputusan:** `burnt`, `mold`, `under` → **EXCLUDED** dari training taxonomy final.
`burnt` tidak otomatis dipetakan ke `scorched`.

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
|---|---|
| defect | 0.40 |
| shape | 0.20 |
| size | 0.20 |
| roast | 0.20 |

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
- **Dua lapisan casing yang sah:** label target *training* = snake_case; enum yang disimpan di DB dan ditampilkan di UI = **Title Case**. Pemetaan eksplisit dicatat di `ARCHITECTURE_ML.md` §3.
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
  - `result`/`ratings` (BrewSpec) dan seluruh log **Dial-in** (BR004) — itu hasil *penyeduhan* pengguna (brew logger), bukan bagian grading biji. Tidak disimpan.

---

## Catatan terbuka (belum diputuskan)

- Ambang confidence untuk status `uncertain` (angka pasti belum ditetapkan).
- Ambang deteksi "mixed batch" (jarak distribusi).
- Cakupan roast untuk robusta hijau (gap DS006 tanpa kelas `Green`).
- Validasi angka bobot quality engine terhadap data nyata.
