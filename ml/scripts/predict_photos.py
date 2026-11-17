#!/usr/bin/env python3
"""Evaluasi model klasifikasi roast pada daftar foto dari manifest (Langkah 4).

Model  : ml/models/roast_exp002_best.pt (YOLOv8n-cls; kelas Dark, Green, Light, Medium)
Input  : manifest CSV dengan kolom `path` dan `roast_label` (atau `label`).
Output : CSV prediksi dengan kolom path, label_true, prediksi, confidence, benar.

Catatan penting:
  - Daftar file dikirim EKSPLISIT ke predict() (bukan folder); predict() menolak
    folder untuk kasus ini.
  - Indeks kelas dipetakan lewat model.names. Model punya 4 kelas, termasuk Green.
    Label evaluasi hanya Dark/Light/Medium. Prediksi Green dihitung SALAH, dan
    jumlahnya dilaporkan terpisah (kolom prediksi == 'Green').
  - Foto tidak pernah dikirim ke server; semua inference lokal.
"""

import argparse
import csv
from collections import Counter
from pathlib import Path

from ultralytics import YOLO


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="ml/data/ds006/manifest_clean.csv")
    ap.add_argument("--model", default="ml/models/roast_exp002_best.pt")
    ap.add_argument("--out", default="ml/data/ds006/predictions.csv")
    ap.add_argument("--label-col", default="roast_label")
    ap.add_argument("--imgsz", type=int, default=224)
    ap.add_argument("--batch", type=int, default=32)
    args = ap.parse_args()

    with open(args.manifest, newline="") as f:
        rows = list(csv.DictReader(f))
    print(f"Manifest : {args.manifest} ({len(rows)} gambar)")
    print(f"Model    : {args.model}")

    paths = [r["path"] for r in rows]
    labels = [r[args.label_col] for r in rows]

    model = YOLO(args.model)
    names = model.names
    print(f"model.names: {names}")

    # daftar file eksplisit, BUKAN folder
    results = model.predict(source=paths, imgsz=args.imgsz, batch=args.batch, verbose=False)

    out_rows = []
    for r, lab, res in zip(rows, labels, results):
        probs = res.probs
        idx = int(probs.top1)
        pred = names[idx]
        conf = float(probs.data[idx])
        out_rows.append({
            "path": r["path"],
            "label_true": lab,
            "prediksi": pred,
            "confidence": f"{conf:.6f}",
            "benar": 1 if pred == lab else 0,
        })

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path", "label_true", "prediksi", "confidence", "benar"])
        w.writeheader()
        w.writerows(out_rows)

    n = len(out_rows)
    benar = sum(r["benar"] for r in out_rows)
    print(f"\n-> {out} ({n} baris)")
    print(f"Akurasi   : {benar}/{n} = {100 * benar / n:0.2f}%")
    print(f"Distribusi prediksi: {dict(sorted(Counter(r['prediksi'] for r in out_rows).items()))}")
    green = sum(1 for r in out_rows if r["prediksi"] == "Green")
    print(f"Prediksi Green (salah menurut definisi): {green}")


if __name__ == "__main__":
    main()
