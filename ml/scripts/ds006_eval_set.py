#!/usr/bin/env python3
"""Susun set evaluasi eksternal DS006 (setelah keputusan user).

Keputusan user: evaluasi HANYA pada bagian Robusta (283 sumber).

Alasan (lihat ml/reports/EXT-ROAST-002-DS006.md):
  - 300 basis DS006 bagian Arabica terbukti bersumber SAMA dengan DS003
    (nama file cocok: dark-N-_png <-> dark (N).png, N=1..100, 100% label cocok).
    DS003 adalah data latih EXP-ROAST-002, jadi Arabica tidak boleh dipakai
    sebagai uji eksternal.
  - Robusta (283 sumber) punya similarity maksimum ke DS003 hanya 0.7849,
    nol pasangan >= 0.93 -> bersih dari kebocoran.

Input : ml/data/ds006/manifest_dedup.csv (583 representan basis)
        ml/data/ds006/leakage_report.csv (hasil Langkah 3)
Output: ml/data/ds006/manifest_clean.csv (283 baris, species_label == Robusta)
"""

import csv
from collections import Counter
from pathlib import Path

D = Path("ml/data/ds006")


def main():
    with open(D / "manifest_dedup.csv", newline="") as f:
        dedup = list(csv.DictReader(f))
    with open(D / "leakage_report.csv", newline="") as f:
        leak = {r["path_ds006"]: r for r in csv.DictReader(f) if r["md5_match"] == "0"}

    keep = []
    dropped_arabica = 0
    dropped_leak = 0
    for r in dedup:
        if r["species_label"] != "Robusta":
            dropped_arabica += 1
            continue
        sim = float(leak[r["path"]]["similarity"])
        if sim >= 0.95:
            dropped_leak += 1
            continue
        keep.append(r)

    print(f"DS006 dedup          : {len(dedup)}")
    print(f"  dibuang (Arabica)  : {dropped_arabica}  (bersumber DS003)")
    print(f"  dibuang (bocor)    : {dropped_leak}  (Robusta dengan sim >= 0.95)")
    print(f"Set evaluasi final   : {len(keep)}")

    out = D / "manifest_clean.csv"
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(dedup[0].keys()))
        w.writeheader()
        w.writerows(keep)
    print(f"\n-> {out}")

    print(f"  per roast   : {dict(sorted(Counter(r['roast_label'] for r in keep).items()))}")
    print(f"  per split   : {dict(sorted(Counter(r['split'] for r in keep).items()))}")
    print(f"  per species : {dict(sorted(Counter(r['species_label'] for r in keep).items()))}")


if __name__ == "__main__":
    main()
