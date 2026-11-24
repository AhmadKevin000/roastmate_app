#!/usr/bin/env python3
"""Isi Template Lampiran D (Milestone 2) dengan hasil nyata model Roast (M3).

Sumber angka:
- Tabel D.1/D.2/D.3 : registries/dataset_registry.csv, registries/split.csv,
                      ml/data/audit_ds003_report.txt
- Tabel D.4         : registries/experiment_registry.csv, reports/EXP-ROAST-002.md,
                      reports/EXT-ROAST-002-DS006.md, plots/classifier/summary.txt
- Tabel D.5         : confusion matrix run v11 (plots/classifier/05_cm_roast.png)
- Tabel D.6         : artefak v10 yang terpasang di aplikasi (nama file + confidence nyata)
"""

import copy
import json
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

SRC = "Template Lampiran D Milestone 2 (Pembelajaran Mesin).docx"
OUT = "Lampiran D Milestone 2 (Pembelajaran Mesin) - Roast.docx"
FIG = Path("ml/reports")
PLOTS = Path("plots/classifier")
CLASSES = ["Green", "Light", "Medium", "Dark"]

# Confusion matrix run v11 (dibaca dari plots/classifier/05_cm_roast.png).
# Baris = label sebenarnya, kolom = prediksi.
CM_V11 = {
    "Green": [45, 0, 0, 0],
    "Light": [1, 43, 1, 0],
    "Medium": [1, 1, 34, 9],
    "Dark": [0, 0, 0, 44],
}

data = json.load(open(FIG / "roast_deployed_eval.json"))


def num(value, digits=4):
    """Format desimal dengan koma (konvensi Indonesia)."""
    return f"{value:.{digits}f}".replace(".", ",")


def per_class_from_cm(cm):
    n = len(CLASSES)
    rows = []
    for i, name in enumerate(CLASSES):
        tp = cm[name][i]
        fn = sum(cm[name]) - tp
        fp = sum(cm[c][i] for c in CLASSES) - tp
        prec = tp / (tp + fp) if tp + fp else 0.0
        rec = tp / (tp + fn) if tp + fn else 0.0
        f1 = 2 * prec * rec / (prec + rec) if prec + rec else 0.0
        rows.append({"class": name, "precision": prec, "recall": rec, "f1": f1,
                     "support": sum(cm[name])})
    return rows


per_class = per_class_from_cm(CM_V11)
n_test = sum(sum(v) for v in CM_V11.values())
acc_v11 = sum(CM_V11[c][i] for i, c in enumerate(CLASSES)) / n_test
macro_f1 = sum(p["f1"] for p in per_class) / len(per_class)
macro_p = sum(p["precision"] for p in per_class) / len(per_class)
macro_r = sum(p["recall"] for p in per_class) / len(per_class)

doc = Document(SRC)
paras = list(doc.paragraphs)


def drop(el):
    el.getparent().remove(el)


def no_border(table):
    """Hilangkan garis tabel pembungkus gambar (1x1) agar bersih."""
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "none")
        el.set(qn("w:sz"), "0")
        borders.append(el)
    table._tbl.tblPr.append(borders)


# --- 1) Buang kotak petunjuk + semua paragraf petunjuk abu-abu ---
drop(doc.tables[0]._tbl)
for idx in (5, 12, 15, 18, 21, 24, 28, 31, 34):
    drop(paras[idx]._element)


# Referensi tabel diambil sekali di awal: penyisipan tabel gambar akan
# menggeser indeks doc.tables.
TBL_D1, TBL_D2, TBL_SAMPEL, TBL_D3, TBL_D4, TBL_D5, TBL_CM, TBL_D6 = doc.tables[:8]


def set_text(p, text, *, italic=False, size=None):
    for r in list(p.runs):
        drop(r._element)
    run = p.add_run(text)
    run.italic = italic
    if size is not None:
        run.font.size = size
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    return run


def set_caption(p, label, text):
    """Caption gaya template: label tebal + teks normal, rata tengah."""
    for r in list(p.runs):
        drop(r._element)
    r1 = p.add_run(label)
    r1.bold = True
    r1.font.size = Pt(11)
    r2 = p.add_run(" " + text)
    r2.font.size = Pt(11)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER


# --- 2) Baris identitas model di bawah judul ---
p_model = paras[3].insert_paragraph_before()
p_model.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p_model.add_run("Model yang dilaporkan: M3 Roast — klasifikasi tingkat sangrai "
                    "(Green / Light / Medium / Dark)")
r.font.size = Pt(10)
r.italic = True


# --- Helper tabel ---
def set_cell(cell, text, *, bold=False, size=Pt(10), align=None):
    for extra in cell.paragraphs[1:]:
        drop(extra._element)
    p = cell.paragraphs[0]
    for run in list(p.runs):
        drop(run._element)
    run = p.add_run(text)
    run.font.size = size
    run.bold = bold
    if align is not None:
        p.alignment = align
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(1)


def insert_row(table, index):
    tr = copy.deepcopy(table.rows[-1]._tr)
    if index >= len(table.rows):
        table._tbl.append(tr)
    else:
        table._tbl.insert(list(table._tbl).index(table.rows[index]._tr), tr)
    return table.rows[index]


def set_widths(table, widths):
    table.autofit = False
    for row in table.rows:
        for cell, w in zip(row.cells, widths):
            cell.width = w
    for col, w in zip(table.columns, widths):
        col.width = w


def figure_block(path, width_in, label, caption_text, insert_before_el):
    """Sisipkan gambar dalam tabel 1x1 tanpa garis + caption di bawahnya."""
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    no_border(tbl)
    cell = tbl.rows[0].cells[0]
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.add_run().add_picture(str(path), width=Inches(width_in))
    insert_before_el.addprevious(tbl._tbl)

    cap = doc.add_paragraph()
    cap.paragraph_format.space_before = Pt(4)
    cap.paragraph_format.space_after = Pt(4)
    set_caption(cap, label, caption_text)
    insert_before_el.addprevious(cap._element)


# --- Tabel D.1 ---
t = TBL_D1
rows = [
    ("Sumber & lisensi",
     "Kaggle — gpiosenka/coffee-bean-dataset-resized-224-x-224, lisensi CC BY-SA 4.0 "
     "(Gerry, 2022). Rujukan: https://www.kaggle.com/datasets/"
     "gpiosenka/coffee-bean-dataset-resized-224-x-224"),
    ("Cara pelabelan",
     "Berlabel dari sumber: satu folder per kelas (Green, Light, Medium, Dark). "
     "Tim tidak melakukan anotasi ulang maupun penggabungan label."),
    ("Jumlah total",
     "1.600 gambar PNG 224×224 (151,3 MB); setelah dedup MD5 menjadi 1.194 gambar unik."),
    ("Pembagian data",
     "Latih 836 / validasi 179 / uji 179 — stratified dan group-aware (unit split = "
     "group_id), seed 42. Sumber kebenaran: registries/split.csv "
     "(SHA256 b75d9a16cae9d4c3…)."),
]
for i, (k, v) in enumerate(rows):
    set_cell(t.rows[i].cells[0], k, bold=True, size=Pt(9))
    set_cell(t.rows[i].cells[1], v, size=Pt(9))
set_widths(t, [Inches(1.35), Inches(4.05)])

# --- Tabel D.2 ---
t = TBL_D2
insert_row(t, 3)
insert_row(t, 3)
dist = {"Green": (209, 45, 45), "Light": (210, 45, 45),
        "Medium": (210, 45, 45), "Dark": (207, 44, 44)}
for i, (name, (tr_, va, te)) in enumerate(dist.items(), start=1):
    total = tr_ + va + te
    pct = 100.0 * total / 1194
    vals = [name, str(tr_), str(va), str(te), f"{total} ({num(pct, 1)}%)"]
    for j, v in enumerate(vals):
        set_cell(t.rows[i].cells[j], v, size=Pt(9),
                 align=WD_ALIGN_PARAGRAPH.CENTER if j else None)
for j, v in enumerate(["Total", "836", "179", "179", "1.194 (100%)"]):
    set_cell(t.rows[5].cells[j], v, bold=True, size=Pt(9),
             align=WD_ALIGN_PARAGRAPH.CENTER if j else None)
set_widths(t, [Inches(1.5), Inches(0.85), Inches(1.0), Inches(0.8), Inches(1.25)])

# --- Gambar D.1 ---
t = TBL_SAMPEL
cell = t.rows[0].cells[0]
for extra in cell.paragraphs[1:]:
    drop(extra._element)
p = cell.paragraphs[0]
for run in list(p.runs):
    drop(run._element)
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
no_border(t)
p.add_run().add_picture(str(FIG / "lampiran_d_sampel.png"), width=Inches(5.2))

# --- Tabel D.3 ---
t = TBL_D3
while len(t.rows) < 8:
    insert_row(t, len(t.rows))
pre = [
    ("1", "Dedup duplikat persis (MD5)",
     "Seluruh isi folder test asli (400 gambar) adalah duplikat byte-identik dari "
     "train sehingga metrik awal mengukur daya hafal",
     "1.194 unik dari 1.600; 406 file dibuang",
     "Seluruh dataset, sebelum split"),
    ("2", "Dedup near-duplicate berbasis embedding",
     "Mencegah foto kembar dari biji yang sama tersebar ke dua split",
     "ResNet-18 ImageNet tanpa fine-tune; cosine ≥ 0,95 → group_id",
     "Seluruh dataset, sebelum split"),
    ("3", "Split group-aware & stratified",
     "Satu grup kemiripan tidak boleh muncul di lebih dari satu split",
     "70/15/15, unit = group_id, seed 42",
     "Pembentukan train/val/test"),
    ("4", "Resize bilinear ke 224×224",
     "Menyamakan ukuran input dengan kontrak training (crop + margin 10%)",
     "224×224, interpolasi bilinear, RGB",
     "Latih, validasi, uji, inference"),
    ("5", "Skala piksel 0..255 tanpa normalisasi",
     "Normalisasi ImageNet sudah berada di dalam model (include_preprocessing)",
     "float32 0..255, layout NHWC",
     "Latih, validasi, uji, inference"),
    ("6", "Augmentasi geometri + kecerahan terbatas",
     "Warna adalah fitur utama roast, sehingga hue dan saturasi tidak boleh berubah",
     "fliplr 0,5; degrees ≤10; translate 0,1; scale 0,1; hsv_h 0; hsv_s 0; hsv_v 0,2",
     "Hanya data latih"),
    ("7", "Kalibrasi kuantisasi dari data latih",
     "Data uji tidak boleh dipakai untuk training maupun kalibrasi",
     "200 gambar, 100% berasal dari split train",
     "Ekspor INT8 (eksperimen E2)"),
]
for i, vals in enumerate(pre, start=1):
    for j, v in enumerate(vals):
        set_cell(t.rows[i].cells[j], v, size=Pt(8.5),
                 align=WD_ALIGN_PARAGRAPH.CENTER if j == 0 else None)
set_widths(t, [Inches(0.32), Inches(1.35), Inches(1.6), Inches(1.35), Inches(0.9)])

# --- Tabel D.4 ---
t = TBL_D4
insert_row(t, 3)
eks = [
    ("E1", "YOLOv8n-cls — DS003 mentah (tanpa dedup)",
     "imgsz 224; batch 32; 50 epoch; augmentasi ringan",
     "tidak dicatat di registry",
     "akurasi 1,0000 — INVALID (kebocoran data)", "—"),
    ("E2", "YOLOv8n-cls — DS003 ter-dedup, split group-aware",
     "imgsz 224; batch 32; 100 epoch (early stop ep. 17); seed 42; hsv_h = hsv_s = 0",
     "tidak dicatat di registry",
     "akurasi 1,0000; macro F1 1,0000 (uji eksternal DS006: 33,92%)", "—"),
    ("E3", "MobileNetV3-Small — DS003 ter-dedup, ekspor fp32",
     "imgsz 224; backbone ImageNet; 11 epoch (early stop); konfigurasi lain tidak "
     "tercatat di registry",
     "≈0,94 (dibaca dari kurva)",
     "≈0,92 (dibaca dari kurva); uji 0,9274", "✓"),
]
for i, vals in enumerate(eks, start=1):
    for j, v in enumerate(vals):
        set_cell(t.rows[i].cells[j], v, size=Pt(8.5),
                 bold=(j == 5 and v == "✓"),
                 align=WD_ALIGN_PARAGRAPH.CENTER if j in (0, 5) else None)
set_widths(t, [Inches(0.35), Inches(1.3), Inches(1.55), Inches(0.95), Inches(1.0),
               Inches(0.35)])

# --- Gambar D.2 & D.3 (bagian D.3) ---
figure_block(PLOTS / "02_roast_curves.png", 4.3, "Gambar D.2",
             "Kurva loss dan akurasi model roast pada data latih dan validasi (run v11)",
             paras[20]._element)
figure_block(PLOTS / "13_tflite_quantization.png", 4.3, "Gambar D.3",
             "Ukuran model dan kesesuaian output TFLite FP32 vs INT8",
             paras[20]._element)

# --- Tabel D.5 (angka run v11) ---
t = TBL_D5
insert_row(t, 3)
insert_row(t, 3)
for i, pc in enumerate(per_class, start=1):
    vals = [pc["class"], num(pc["precision"]), num(pc["recall"]),
            num(pc["f1"]), str(pc["support"])]
    for j, v in enumerate(vals):
        set_cell(t.rows[i].cells[j], v, size=Pt(9),
                 align=WD_ALIGN_PARAGRAPH.CENTER if j else None)
macro = ("Rata-rata makro", num(macro_p), num(macro_r), num(macro_f1), str(n_test))
for j, v in enumerate(macro):
    set_cell(t.rows[5].cells[j], v, bold=True, size=Pt(9),
             align=WD_ALIGN_PARAGRAPH.CENTER if j else None)
set_widths(t, [Inches(1.15), Inches(0.85), Inches(0.8), Inches(0.85), Inches(0.9)])

# --- Catatan provenance ---
set_text(paras[26],
         "Angka pada Tabel D.5 dan Gambar D.4 dihitung dari confusion matrix run v11 "
         "(plots/classifier/05_cm_roast.png, n = 179) dan konsisten dengan "
         "plots/classifier/summary.txt (akurasi 0,9274; macro F1 0,9254). Contoh pada "
         "Tabel D.6 diukur dari artefak v10 yang saat ini terpasang di aplikasi "
         "(assets/models/roast_classifier.tflite), karena model v11 belum ditarik ke "
         "repo; pola kesalahannya sama, yaitu Medium→Dark.",
         italic=True, size=Pt(9))

# --- Gambar D.4 (confusion matrix run v11) ---
t = TBL_CM
cell = t.rows[0].cells[0]
for extra in cell.paragraphs[1:]:
    drop(extra._element)
p = cell.paragraphs[0]
for run in list(p.runs):
    drop(run._element)
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
no_border(t)
p.add_run().add_picture(str(PLOTS / "05_cm_roast.png"), width=Inches(2.9))
set_caption(paras[27], "Gambar D.4", "Confusion matrix pada data uji")

# --- Tabel D.6 ---
cap_d6 = paras[29]
tbl_d6_el = TBL_D6._tbl
tbl_d6_el.addprevious(cap_d6._element)

t = TBL_D6
errs = data["test_errors"][:3]
causes = [
    "Model sangat yakin (0,95) tetapi salah; kandidat label noise atau biji berada "
    "di batas Dark. Termasuk kelompok pasangan lintas kelas Dark↔Medium yang muncul "
    "pada similarity 0,94.",
    "Kesalahan pada batas Medium→Dark dengan keyakinan sedang; warna permukaan lebih "
    "gelap daripada Medium lain di kelas yang sama.",
    "Kesalahan ke arah sebaliknya (Medium→Light), menunjukkan kelas Medium diapit dua "
    "batas yang sama-sama tipis.",
]
for i, (err, cause) in enumerate(zip(errs, causes), start=1):
    row = t.rows[i]
    set_cell(row.cells[0], str(i), size=Pt(9), align=WD_ALIGN_PARAGRAPH.CENTER)
    cell = row.cells[1]
    for extra in cell.paragraphs[1:]:
        drop(extra._element)
    p = cell.paragraphs[0]
    for run in list(p.runs):
        drop(run._element)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(str(FIG / f"lampiran_d_err{i}.png"), width=Inches(0.62))
    cap = cell.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cr = cap.add_run(Path(err["file"]).name)
    cr.font.size = Pt(7)
    set_cell(row.cells[2], err["true"], size=Pt(9),
             align=WD_ALIGN_PARAGRAPH.CENTER)
    set_cell(row.cells[3], f"{err['pred']} ({num(err['conf'], 2)})", size=Pt(9),
             align=WD_ALIGN_PARAGRAPH.CENTER)
    set_cell(row.cells[4], cause, size=Pt(8.5))
set_widths(t, [Inches(0.3), Inches(1.25), Inches(0.75), Inches(0.95), Inches(2.15)])

# --- Gambar D.5: kalibrasi (mendukung ambang confidence di aplikasi) ---
figure_block(PLOTS / "09_calibration.png", 2.7, "Gambar D.5",
             "Reliability diagram ketiga classifier; garis hijau adalah model roast",
             paras[32]._element)


# --- Gambar D.6: histogram confidence model roast ---
figure_block(PLOTS / "08_confidence_hist.png", 5.0, "Gambar D.6",
             "Histogram probabilitas maksimum model roast pada data uji; "
             "biru = prediksi benar, oranye = prediksi salah (panel ketiga)",
             paras[32]._element)


# --- Narasi analisis ---
set_text(paras[13],
         "Sebaran kelas DS-ROAST hampir sempurna seimbang: setiap kelas menyumbang "
         "24,7–25,1% dari 1.194 gambar (Tabel D.2), sehingga ketidakseimbangan kelas "
         "bukan sumber masalah pada model ini dan tidak ada class weighting maupun "
         "oversampling yang diterapkan. Kualitas data justru bermasalah: audit MD5 "
         "menemukan 809 dari 1.600 file (50,6%) merupakan duplikat persis, dan seluruh "
         "400 gambar pada folder test asli memiliki kembaran byte-identik di folder "
         "train. Kondisi ini membuat skor validasi dan uji pada dataset mentah "
         "mengukur daya hafal, bukan generalisasi; penanganannya adalah dedup MD5, "
         "dilanjutkan dedup near-duplicate berbasis embedding ResNet-18 pada ambang "
         "cosine 0,95, lalu split group-aware agar satu grup kemiripan tidak pernah "
         "masuk dua split sekaligus (Tabel D.3).")

set_text(paras[22],
         "Perubahan yang paling berpengaruh adalah penghapusan kebocoran data, bukan "
         "arsitektur maupun hiperparameter: E1 yang dilatih pada DS003 mentah meraih "
         "akurasi 1,0000 pada validasi dan uji, tetapi model hasil E2 (arsitektur "
         "YOLOv8n-cls) hanya mencapai 33,92% ketika diuji pada 283 foto Robusta dari "
         "sumber lain (DS006). Setelah dedup dan split group-aware, metrik in-domain "
         "kembali tinggi karena DS003 memang homogen, sehingga evaluasi eksternal "
         "menjadi pembeda utama. Model MobileNetV3-Small (E3) yang dipakai sekarang "
         "memperoleh akurasi uji 0,9274 dengan macro F1 0,9254; kurvanya (Gambar D.2) "
         "berhenti pada epoch ke-11 dengan akurasi latih ≈0,94 dan validasi ≈0,92, dan "
         "akurasi validasi berada di atas akurasi latih pada sebagian besar epoch "
         "sehingga tidak ada indikasi overfitting. E3 dipilih karena satu-satunya "
         "kandidat yang lolos syarat produksi: classifier diekspor fp32 (Gambar D.3), "
         "sebab kuantisasi INT8 menurunkan agreement argmax di bawah 1,0.")

set_text(paras[32],
         "Kelas terlemah adalah Medium dengan recall 0,7556: dari 45 biji Medium, 9 "
         "diprediksi sebagai Dark, 1 sebagai Light, dan 1 sebagai Green, sedangkan "
         "Light menyumbang dua kesalahan (1 ke Green dan 1 ke Medium) sementara Green "
         "dan Dark nyaris sempurna (Tabel D.5, Gambar D.4). Pola ini berkaitan "
         "langsung dengan temuan D.1, karena pada ambang kemiripan 0,94 sudah muncul "
         "pasangan lintas kelas Dark↔Medium di DS003, sehingga sebagian batas "
         "Medium–Dark memang ambigu secara visual, bukan semata kesalahan model. "
         "Akurasi uji 0,9274 konsisten dengan akurasi validasi ≈0,92, jadi tidak ada "
         "indikasi overfitting. Namun validasi dan uji sama-sama berasal dari domain "
         "studio yang identik dengan data latih, sehingga angka ini tetap belum "
         "mewakili foto pengguna nyata.")

set_text(paras[35],
         "Sumber masalah utama model roast saat ini adalah data, bukan arsitektur atau "
         "praproses: DS003 mengandung 50,6% duplikat persis dengan folder test yang "
         "seluruhnya kembar byte-identik dengan train (D.1), dan bahkan setelah "
         "kebocoran itu dihapus model hanya mencapai 33,92% pada foto Robusta dari "
         "sumber lain (D.3). Praproses yang diterapkan sudah konsisten dengan kontrak "
         "224 bilinear 0..255 (D.2), sedangkan arsitektur tidak menunjukkan overfitting "
         "karena akurasi validasi justru lebih tinggi daripada akurasi latih (D.3). "
         "Kesalahan yang tersisa terkonsentrasi pada batas Medium–Dark dengan recall "
         "Medium 0,7556 (D.4), batas yang memang ambigu secara visual pada dataset ini. "
         "Perbaikan karena itu harus berupa penambahan data dari domain pengguna "
         "(DS010), bukan penyetelan hiperparameter.")

# --- Cegah caption terpisah dari tabel/gambar, dan baris tabel terpotong ---
from docx.oxml.ns import qn as _qn

for par in doc.paragraphs:
    txt = par.text.strip()
    if txt.startswith(("Tabel D.", "Gambar D.")):
        par.paragraph_format.keep_with_next = True
    if txt.startswith(("D.1 ", "D.2 ", "D.3 ", "D.4 ", "D.5 ",
                       "Analisis Dataset", "Analisis Eksperimen",
                       "Analisis Hasil Evaluasi")):
        par.paragraph_format.keep_with_next = True

for tbl in doc.tables:
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    for row in tbl.rows:
        trPr = row._tr.get_or_add_trPr()
        if trPr.find(_qn("w:cantSplit")) is None:
            trPr.append(OxmlElement("w:cantSplit"))

doc.save(OUT)
print("saved:", OUT)
print(f"uji v11: acc={num(acc_v11)} macroF1={num(macro_f1)} n={n_test}")
