#!/usr/bin/env python3
"""Materialisasi dataset ke struktur Ultralytics + folder kalibrasi INT8 (Langkah 4).

Input : ml/registries/split.csv, gambar mentah di ml/data/ds003/
Output:
  ml/data/ds003_dedup/{train,val,test}/{class}/*
  ml/data/calib/{train,val}/{class}/*   -> 200 gambar, SEMUA dari split train (seed 42)
  ml/data/calib_manifest.csv            -> bukti asal tiap gambar kalibrasi

Kenapa calib/ terstruktur (train/ + val/)?
  Ultralytics `check_cls_dataset()` untuk kalibrasi INT8 klasifikasi memakai
  split "val" secara default, dan bila folder `train/` tidak ada ia akan
  MEMBUAT SPLIT ACAK 80/20 sendiri. Itu dilarang. Maka calib/ dibuat
  terstruktur; isi `train/` dan `val/` identik dan keduanya berasal dari
  split train saja (tidak ada gambar test).

Isi ml/data/ sudah gitignored, jangan di-commit.
"""

import argparse
import csv
import random
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

IMG_EXT = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--split", default="ml/registries/split.csv")
    ap.add_argument("--raw", default="ml/data/ds003")
    ap.add_argument("--out", default="ml/data/ds003_dedup")
    ap.add_argument("--calib", default="ml/data/calib")
    ap.add_argument("--calib-n", type=int, default=200)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    raw = Path(args.raw)
    out = Path(args.out)
    calib = Path(args.calib)

    with open(args.split, newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        sys.exit("split.csv kosong")

    for d in (out, calib):
        if d.exists():
            shutil.rmtree(d)

    counts = defaultdict(Counter)
    for r in rows:
        src = raw / r["path"]
        if not src.is_file():
            sys.exit(f"Sumber tidak ada: {src}")
        dst_dir = out / r["split"] / r["class"]
        dst_dir.mkdir(parents=True, exist_ok=True)
        name = src.name
        if (dst_dir / name).exists():
            name = f"{src.stem}__{abs(hash(r['path'])) % 10**8}{src.suffix}"
        shutil.copy2(src, dst_dir / name)
        counts[r["split"]][r["class"]] += 1

    # --- kalibrasi: HANYA dari split train ---
    train = [r for r in rows if r["split"] == "train"]
    rng = random.Random(args.seed)
    pick = rng.sample(train, min(args.calib_n, len(train)))
    train_paths = {r["path"] for r in train}
    bad = [r["path"] for r in pick if r["path"] not in train_paths]
    if bad:
        sys.exit(f"BUG: calib mengambil dari luar train: {bad[:3]}")

    calib_rows = []
    for i, r in enumerate(pick):
        src = raw / r["path"]
        for sub in ("train", "val"):
            d = calib / sub / r["class"]
            d.mkdir(parents=True, exist_ok=True)
            dst = d / f"{src.stem}{src.suffix}"
            shutil.copy2(src, dst)
            calib_rows.append({"calib_path": str(dst.relative_to(calib)), "source_path": r["path"], "source_split": "train"})

    with open(calib.parent / "calib_manifest.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["calib_path", "source_path", "source_split"])
        w.writeheader()
        w.writerows(calib_rows)

    # --- verifikasi ---
    errs = []
    if any(r["source_split"] != "train" for r in calib_rows):
        errs.append("ada gambar kalibrasi bukan dari split train")
    srcs = [r["source_path"] for r in calib_rows]
    if len(set(srcs)) != args.calib_n:
        errs.append(f"jumlah sumber kalibrasi unik = {len(set(srcs))}, harus {args.calib_n}")
    test_names = {Path(r['path']).name for r in rows if r['split'] == 'test'}
    leaked = sorted(test_names & {Path(s).name for s in srcs})
    # nama bisa kebetulan sama antar kelas; cek lewat path lengkap
    test_paths = {r['path'] for r in rows if r['split'] == 'test'}
    if set(srcs) & test_paths:
        errs.append("ada gambar test yang masuk kalibrasi")

    print(f"{'kelas':<8}{'train':>8}{'val':>7}{'test':>7}{'total':>8}")
    print("-" * 38)
    classes = sorted({r["class"] for r in rows})
    for c in classes:
        t = sum(counts[s][c] for s in ("train", "val", "test"))
        print(f"{c:<8}{counts['train'][c]:>8}{counts['val'][c]:>7}{counts['test'][c]:>7}{t:>8}")
    print("-" * 38)
    tot = {s: sum(counts[s][c] for c in classes) for s in ("train", "val", "test")}
    print(f"{'TOTAL':<8}{tot['train']:>8}{tot['val']:>7}{tot['test']:>7}{sum(tot.values()):>8}")

    print(f"\nDataset  : {out}")
    print(f"Kalibrasi: {calib} ({len(set(srcs))} gambar unik, semua dari split train)")
    print(f"  calib/train = {sum(1 for r in calib_rows if r['calib_path'].startswith('train'))} file")
    print(f"  calib/val   = {sum(1 for r in calib_rows if r['calib_path'].startswith('val'))} file")
    print(f"Manifest kalibrasi: {calib.parent / 'calib_manifest.csv'}")

    if errs:
        sys.exit("\nVERIFIKASI GAGAL:\n  - " + "\n  - ".join(errs))
    print("\nVerifikasi OK: kalibrasi hanya dari split train, tidak ada gambar test.")


if __name__ == "__main__":
    main()
