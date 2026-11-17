#!/usr/bin/env python3
"""Bangun manifest DS006 (Kopi Robusta dan Arabika) untuk evaluasi eksternal roast.

DS006 TIDAK PERNAH dipakai untuk training/validasi/kalibrasi. Manifest ini murni
daftar gambar evaluasi.

Struktur sumber:
  ml/data/ds006/{train,valid,test}/<Species> <Roast>/<file>

Pemetaan label EKSPLISIT (tidak ada penggabungan dengan label DS003):
  species_label : token pertama nama folder  -> Arabica | Robusta
  roast_label   : token terakhir nama folder -> Dark | Light | Medium
  (DS006 tidak punya kelas Green; tidak ada pemetaan dari kelas lain ke Green)

Output: ml/data/ds006/manifest.csv
  kolom: path, md5, split, species_label, roast_label
  path relatif terhadap root repo, mis.
    ml/data/ds006/train/Arabica Dark/dark-1-_png.rf.<hash>.jpg

Skrip GAGAL bila:
  - folder train/valid/test tidak ada,
  - ada nama folder yang tidak bisa diparse jadi (species, roast),
  - ada roast_label di luar {Dark, Light, Medium}.
"""

import csv
import hashlib
import sys
from collections import Counter
from pathlib import Path

ROOT = Path("ml/data/ds006")
SPLITS = ["train", "valid", "test"]
SPECIES = {"Arabica", "Robusta"}
ROAST = {"Dark", "Light", "Medium"}
EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def md5_of(path, chunk=1 << 20):
    h = hashlib.md5()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def main():
    if not ROOT.is_dir():
        sys.exit(f"Folder {ROOT} tidak ada")

    for s in SPLITS:
        if not (ROOT / s).is_dir():
            sys.exit(f"Split {s} tidak ada di {ROOT}")

    rows = []
    bad_names = []
    for s in SPLITS:
        for cls_dir in sorted((ROOT / s).iterdir()):
            if not cls_dir.is_dir():
                continue
            name = cls_dir.name
            parts = name.split()
            if len(parts) < 2:
                bad_names.append(f"{s}/{name}")
                continue
            species, roast = parts[0], parts[-1]
            if species not in SPECIES or roast not in ROAST:
                bad_names.append(f"{s}/{name} (species={species}, roast={roast})")
                continue
            for f in sorted(cls_dir.iterdir()):
                if f.suffix.lower() not in EXTS:
                    continue
                rows.append({
                    "path": str(f),
                    "md5": md5_of(f),
                    "split": s,
                    "species_label": species,
                    "roast_label": roast,
                })

    if bad_names:
        sys.exit("Nama folder tidak sesuai pola '<Species> <Roast>':\n  - " + "\n  - ".join(bad_names))

    if not rows:
        sys.exit("Tidak ada gambar ditemukan")

    out = ROOT / "manifest.csv"
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["path", "md5", "split", "species_label", "roast_label"])
        w.writeheader()
        w.writerows(rows)

    print(f"Manifest       : {out}")
    print(f"Total gambar   : {len(rows)}")
    print(f"MD5 unik       : {len(set(r['md5'] for r in rows))}")

    print("\nPer split:")
    for s in SPLITS:
        print(f"  {s:<6} {sum(1 for r in rows if r['split'] == s)}")

    print("\nPer roast_label:")
    for k, v in sorted(Counter(r["roast_label"] for r in rows).items()):
        print(f"  {k:<8} {v}")

    print("\nPer species_label:")
    for k, v in sorted(Counter(r["species_label"] for r in rows).items()):
        print(f"  {k:<8} {v}")

    print("\nPer (split, species, roast):")
    t = Counter((r["split"], r["species_label"], r["roast_label"]) for r in rows)
    for s in SPLITS:
        for sp in sorted(SPECIES):
            for ro in ["Dark", "Light", "Medium"]:
                if t[(s, sp, ro)]:
                    print(f"  {s:<6} {sp:<8} {ro:<7} {t[(s, sp, ro)]}")


if __name__ == "__main__":
    main()
