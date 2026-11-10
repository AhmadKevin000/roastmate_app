#!/usr/bin/env python3
"""Split grup-aware + stratified untuk DS003 hasil dedup (Langkah 3).

Unit split adalah `group_id` (hasil embed_dedup.py) supaya near-duplicate tidak
terpisah antar split. Stratified per kelas, rasio 70/15/15, seed 42.
Hanya baris keep=1 yang displit.

Input : ml/data/manifest.csv (harus sudah punya kolom group_id)
Output: ml/registries/split.csv -> path,class,group_id,split,seed

Skrip GAGAL (exit != 0) bila verifikasi tidak lolos:
  a. ada group_id yang muncul di lebih dari satu split
  b. ada kelas yang tidak muncul di salah satu split
  c. ada path yang muncul lebih dari sekali
"""

import argparse
import csv
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

SPLITS = ["train", "val", "test"]
TARGETS = {"train": 0.70, "val": 0.15, "test": 0.15}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="ml/data/manifest.csv")
    ap.add_argument("--out", default="ml/registries/split.csv")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    with open(args.manifest, newline="") as f:
        rows = [r for r in csv.DictReader(f) if r["keep"] == "1"]
    if not rows:
        sys.exit("Tidak ada baris keep=1 di manifest")

    members = defaultdict(list)
    for r in rows:
        members[r["group_id"]].append(r)

    # kelas tiap grup = kelas mayoritas anggota
    group_class = {}
    for gid, mem in members.items():
        c = Counter(m["class"] for m in mem)
        top = c.most_common()
        if len(top) > 1 and top[0][1] == top[1][1]:
            print(f"  WARN grup {gid} lintas kelas: {dict(c)}")
        group_class[gid] = sorted(c.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]

    total = len(rows)
    rng = random.Random(args.seed)
    per_class = defaultdict(list)
    for gid in members:
        per_class[group_class[gid]].append(gid)

    # greedy: tiap grup masuk split dengan rasio-terisi terkecil (menjaga 70/15/15)
    counts = {s: 0 for s in SPLITS}
    assign = {}
    for cls in sorted(per_class):
        gids = per_class[cls]
        rng.shuffle(gids)
        for gid in gids:
            sz = len(members[gid])
            best = min(SPLITS, key=lambda s: (counts[s] + sz) / (TARGETS[s] * total))
            assign[gid] = best
            counts[best] += sz

    out_rows = [{
        "path": r["path"],
        "class": r["class"],
        "group_id": r["group_id"],
        "split": assign[r["group_id"]],
        "seed": args.seed,
    } for r in rows]
    out_rows.sort(key=lambda r: (SPLITS.index(r["split"]), r["class"], r["path"]))

    # --- verifikasi ---
    errs = []
    g_splits = defaultdict(set)
    for r in out_rows:
        g_splits[r["group_id"]].add(r["split"])
    bad = {g: sorted(s) for g, s in g_splits.items() if len(s) > 1}
    if bad:
        errs.append(f"(a) group_id lintas split: {list(bad.items())[:5]}")

    paths = [r["path"] for r in out_rows]
    dup = [p for p, c in Counter(paths).items() if c > 1]
    if dup:
        errs.append(f"(c) path duplikat: {dup[:5]}")

    table = defaultdict(Counter)
    for r in out_rows:
        table[r["class"]][r["split"]] += 1
    for cls in table:
        for s in SPLITS:
            if table[cls][s] == 0:
                errs.append(f"(b) kelas {cls} kosong di split {s}")

    print(f"\n{'kelas':<8}{'train':>8}{'val':>7}{'test':>7}{'total':>8}")
    print("-" * 38)
    for cls in sorted(table):
        t = sum(table[cls][s] for s in SPLITS)
        print(f"{cls:<8}{table[cls]['train']:>8}{table[cls]['val']:>7}{table[cls]['test']:>7}{t:>8}")
    print("-" * 38)
    tot = {s: sum(table[c][s] for c in table) for s in SPLITS}
    print(f"{'TOTAL':<8}{tot['train']:>8}{tot['val']:>7}{tot['test']:>7}{sum(tot.values()):>8}")
    print(f"\nGrup: {len(members)} | gambar: {total} | seed: {args.seed}")

    if errs:
        sys.exit("\nVERIFIKASI GAGAL:\n  - " + "\n  - ".join(errs))
    print("Verifikasi OK: (a) tidak ada group_id lintas split, (b) semua kelas ada di 3 split, (c) tidak ada path duplikat")

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path", "class", "group_id", "split", "seed"])
        w.writeheader()
        w.writerows(out_rows)
    print(f"split.csv -> {out}")


if __name__ == "__main__":
    main()
