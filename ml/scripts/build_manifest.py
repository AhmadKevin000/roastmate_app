#!/usr/bin/env python3
"""Bangun manifest per-file untuk dataset DS003: tandai duplikat persis (MD5).

Aturan pemilihan representan (keep=1) per grup MD5:
  1. Prioritaskan file dari folder `train/`.
  2. Di antara kandidat terpilih, ambil nama file terkecil secara leksikografis.
  3. Jika tidak ada file `train/`, pakai path terkecil secara leksikografis.
File lain dalam grup yang sama ditandai keep=0 (tidak dihapus).

Output: ml/data/manifest.csv
  kolom: path, md5, class, dup_group_id, keep

Contoh:
  python3 ml/scripts/build_manifest.py ml/data/ds003 \
      --label-map '{"dark":"Dark","green":"Green","light":"Light","medium":"Medium"}' \
      --out ml/data/manifest.csv --expected-unique 1194
"""

import argparse
import csv
import hashlib
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

IMG_EXT = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


def find_images(root: Path):
    return sorted(p for p in root.rglob("*") if p.suffix.lower() in IMG_EXT)


def md5_of(path: Path, chunk=1 << 20):
    h = hashlib.md5()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def pick_representative(entries):
    """entries: list of dict(path, split, name). Kembalikan index representan."""
    train = [e for e in entries if e["split"] == "train"]
    pool = train if train else entries
    pool = sorted(pool, key=lambda e: (e["name"], e["path"]))
    return pool[0]["path"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dataset_dir")
    ap.add_argument("--label-map", default=None, help="JSON mapping folder->label")
    ap.add_argument("--out", default="ml/data/manifest.csv")
    ap.add_argument("--expected-unique", type=int, default=None)
    args = ap.parse_args()

    root = Path(args.dataset_dir)
    if not root.is_dir():
        sys.exit(f"Bukan direktori: {root}")
    label_map = json.loads(args.label_map) if args.label_map else None

    imgs = find_images(root)
    if not imgs:
        sys.exit("Tidak ada gambar ditemukan")

    records = []
    for p in imgs:
        rel = p.relative_to(root)
        parts = rel.parts
        folder = parts[-2] if len(parts) >= 2 else "(root)"
        cls = folder
        if label_map:
            cls = label_map.get(folder.lower().replace(" ", "_"), folder)
        records.append({
            "path": str(rel),
            "split": parts[0] if len(parts) >= 2 else "(root)",
            "name": p.name,
            "class": cls,
            "md5": md5_of(p),
        })

    by_md5 = defaultdict(list)
    for r in records:
        by_md5[r["md5"]].append(r)

    # grup diurutkan supaya dup_group_id deterministik
    groups = sorted(by_md5.items(), key=lambda kv: min(e["path"] for e in kv[1]))
    md5_to_group = {}
    for i, (h, entries) in enumerate(groups, start=1):
        md5_to_group[h] = f"G{i:04d}"

    rows = []
    for h, entries in groups:
        gid = md5_to_group[h]
        rep = pick_representative(entries)
        for e in entries:
            rows.append({
                "path": e["path"],
                "md5": h,
                "class": e["class"],
                "dup_group_id": gid,
                "keep": 1 if e["path"] == rep else 0,
            })

    rows.sort(key=lambda r: r["path"])

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path", "md5", "class", "dup_group_id", "keep"])
        w.writeheader()
        w.writerows(rows)

    n_total = len(rows)
    n_keep = sum(r["keep"] for r in rows)
    n_groups = len(groups)
    print(f"Total file     : {n_total}")
    print(f"Grup MD5       : {n_groups}")
    print(f"keep=1 (unik)  : {n_keep}")
    print(f"keep=0 (dup)   : {n_total - n_keep}")
    print("\nJumlah per kelas (keep=1):")
    for c, k in sorted(Counter(r["class"] for r in rows if r["keep"] == 1).items()):
        total = sum(1 for r in rows if r["class"] == c)
        print(f"  {c:<8} : keep={k:>4} / total={total}")
    print(f"\nManifest -> {out}")

    if args.expected_unique is not None and n_keep != args.expected_unique:
        sys.exit(f"\nBERHENTI: keep=1 = {n_keep}, diharapkan {args.expected_unique}.")
    if args.expected_unique is not None:
        print(f"Verifikasi OK: keep=1 == {args.expected_unique}")


if __name__ == "__main__":
    main()
