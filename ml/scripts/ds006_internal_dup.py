#!/usr/bin/env python3
"""Dedup internal DS006 berdasarkan BASIS NAMA FILE (Langkah 2, revisi).

Mengapa bukan union-find 0.95: pada DS006 ambang 0.95 menghasilkan 488 pasangan
LINTAS ROAST (Dark/Light/Medium Robusta saling mirip), sehingga union-find
menggabungkan 596 gambar dari 3 kelas berbeda jadi satu grup (chaining). Grup
itu tidak bermakna. Lihat ml/reports/EXT-ROAST-002-DS006.md bagian temuan.

Karena itu grup duplikat internal ditentukan oleh PROVENANCE augmentasi Roboflow
yang eksak dan deterministik: nama file
    <basis_sumber>.rf.<hash>.jpg
Basis = nama file tanpa pola `.rf.<hash>` di depan ekstensi. README.roboflow.txt
menyatakan tiap gambar sumber dibuat 3 versi augmentasi.

Aturan representan (satu per basis), prioritas:
  1. split test
  2. split valid
  3. split train
  4. nama file terkecil secara leksikografis

Output:
  ml/data/ds006/internal_dup_report.csv
    pasangan yang berbagi basis yang sama, plus pasangan MD5 identik.
    kolom: path_a, path_b, split_a, split_b, md5_match, similarity
  ml/data/ds006/manifest_dedup.csv
    583 representan (1 per basis sumber).
    kolom: path, md5, split, species_label, roast_label, base, group_size, is_representative

Skrip juga melaporkan (tanpa membuang) pasangan lintas roast dengan
cosine similarity >= 0.95 di dalam 583 gambar, sebagai keterbatasan label.
"""

import argparse
import csv
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import torch
import torchvision
from PIL import Image
from torchvision import transforms

SPLIT_PRIORITY = {"test": 0, "valid": 1, "train": 2}
RF_SUFFIX = re.compile(r"^(?P<base>.*?)\.rf\.[0-9a-f]+\.(?P<ext>jpg|jpeg|png|bmp|webp)$", re.IGNORECASE)
ROASTS = ["Dark", "Light", "Medium"]


def source_base(path):
    """Nama file tanpa pola .rf.<hash>; fallback ke nama file utuh."""
    name = Path(path).name
    m = RF_SUFFIX.match(name)
    return m.group("base") if m else name


def build_model():
    weights = torchvision.models.ResNet18_Weights.IMAGENET1K_V1
    model = torchvision.models.resnet18(weights=weights)
    model.fc = torch.nn.Identity()
    model.eval()
    return model


def make_transform(img_size=224):
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(img_size),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])


@torch.no_grad()
def compute_embeddings(model, tfm, paths, batch_size=32):
    feats = []
    for i in range(0, len(paths), batch_size):
        chunk = paths[i:i + batch_size]
        imgs = []
        for p in chunk:
            with Image.open(p) as im:
                imgs.append(tfm(im.convert("RGB")))
        feats.append(model(torch.stack(imgs)).cpu().numpy().astype(np.float32))
    emb = np.concatenate(feats, axis=0)
    norms = np.linalg.norm(emb, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    return emb / norms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="ml/data/ds006/manifest.csv")
    ap.add_argument("--outdir", default="ml/data/ds006")
    ap.add_argument("--threshold", type=float, default=0.95)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    torch.manual_seed(args.seed)
    np.random.seed(args.seed)

    with open(args.manifest, newline="") as f:
        rows = list(csv.DictReader(f))
    print(f"Manifest       : {args.manifest} ({len(rows)} gambar)")

    for r in rows:
        r["base"] = source_base(r["path"])

    # ---------- MD5 ----------
    by_md5 = defaultdict(list)
    for i, r in enumerate(rows):
        by_md5[r["md5"]].append(i)
    md5_pairs = set()
    for idxs in by_md5.values():
        for a in range(len(idxs)):
            for b in range(a + 1, len(idxs)):
                md5_pairs.add((idxs[a], idxs[b]))
    print(f"MD5 persis     : {len(md5_pairs)} pasangan | md5 unik: {len(by_md5)}")

    # ---------- grup basis ----------
    by_base = defaultdict(list)
    for i, r in enumerate(rows):
        by_base[r["base"]].append(i)
    size_hist = Counter(len(v) for v in by_base.values())
    print(f"Basis sumber   : {len(by_base)} | sebaran ukuran: {dict(sorted(size_hist.items()))}")

    reps = {}
    for b, idxs in by_base.items():
        idxs_sorted = sorted(idxs, key=lambda i: (SPLIT_PRIORITY[rows[i]["split"]], Path(rows[i]["path"]).name))
        reps[b] = idxs_sorted[0]

    # verifikasi: tepat satu representan per basis
    assert len(reps) == len(by_base), "jumlah representan != jumlah basis"
    assert len(set(reps.values())) == len(reps), "ada gambar jadi representan lebih dari satu basis"
    print(f"Representan    : {len(reps)} (verifikasi: 1 per basis, unik) -> OK")

    # ---------- embedding 583 representan ----------
    rep_rows = [rows[reps[b]] for b in sorted(reps)]
    rep_paths = [r["path"] for r in rep_rows]
    model = build_model()
    emb = compute_embeddings(model, make_transform(), rep_paths)
    print(f"Embeddings     : {emb.shape}")

    # ---------- pasangan lintas roast >= threshold (dilaporkan, tidak dibuang) ----------
    sim = emb @ emb.T
    n = len(rep_paths)
    roast = [r["roast_label"] for r in rep_rows]
    species = [r["species_label"] for r in rep_rows]
    split = [r["split"] for r in rep_rows]
    iu = np.triu_indices(n, k=1)
    vals = sim[iu]
    pair_roast = Counter()
    pair_species = Counter()
    for k in range(len(iu[0])):
        if vals[k] < args.threshold:
            continue
        a, b = int(iu[0][k]), int(iu[1][k])
        key = tuple(sorted([roast[a], roast[b]]))
        pair_roast[key] += 1
        skey = tuple(sorted([species[a], species[b]]))
        pair_species[skey] += 1

    print(f"\nPasangan similarity >= {args.threshold} di dalam {n} representan: {int((vals >= args.threshold).sum())}")
    print("  per pasangan roast:")
    for k in [("Dark", "Dark"), ("Light", "Light"), ("Medium", "Medium"),
              ("Dark", "Light"), ("Dark", "Medium"), ("Light", "Medium")]:
        if pair_roast[k]:
            print(f"    {k[0]:<6}-{k[1]:<6} {pair_roast[k]}")
    cross = sum(v for k, v in pair_roast.items() if k[0] != k[1])
    print(f"  total LINTAS roast: {cross}  | lintas species: {sum(v for k,v in pair_species.items() if k[0]!=k[1])}")

    # pasangan lintas split (informasi)
    pair_split = Counter()
    for k in range(len(iu[0])):
        if vals[k] < args.threshold:
            continue
        a, b = int(iu[0][k]), int(iu[1][k])
        pair_split[tuple(sorted([split[a], split[b]]))] += 1
    print("  per pasangan split:")
    for k, v in sorted(pair_split.items()):
        print(f"    {k[0]:<6}-{k[1]:<6} {v}")

    # ---------- internal_dup_report.csv ----------
    rep_idx_map = {rows[i]["path"]: i for i in range(len(rows))}
    rep_of_base = {b: rows[reps[b]]["path"] for b in by_base}
    sim_of = {}
    for i in range(n):
        sim_of[rep_paths[i]] = i
    out_rows = []
    for b, idxs in by_base.items():
        if len(idxs) < 2:
            continue
        rep = reps[b]
        for i in idxs:
            if i == rep:
                continue
            a_path, b_path = rows[rep]["path"], rows[i]["path"]
            ra, rb = sim_of.get(a_path), sim_of.get(b_path)
            s = float(sim[ra, rb]) if (ra is not None and rb is not None) else ""
            out_rows.append({
                "path_a": a_path, "path_b": b_path,
                "split_a": rows[rep]["split"], "split_b": rows[i]["split"],
                "md5_match": 1 if tuple(sorted((rep, i))) in md5_pairs else 0,
                "similarity": f"{s:.6f}" if s != "" else "",
            })
    # pasangan MD5 yang tidak satu basis
    for a, b in sorted(md5_pairs):
        if rows[a]["base"] == rows[b]["base"]:
            continue
        out_rows.append({
            "path_a": rows[a]["path"], "path_b": rows[b]["path"],
            "split_a": rows[a]["split"], "split_b": rows[b]["split"],
            "md5_match": 1, "similarity": "1.000000",
        })
    rep_path = Path(args.outdir) / "internal_dup_report.csv"
    with open(rep_path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path_a", "path_b", "split_a", "split_b", "md5_match", "similarity"])
        w.writeheader()
        w.writerows(out_rows)
    print(f"\nLaporan pasangan: {rep_path} ({len(out_rows)} baris)")

    # ---------- manifest_dedup.csv ----------
    out2 = Path(args.outdir) / "manifest_dedup.csv"
    with open(out2, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path", "md5", "split", "species_label", "roast_label",
                                          "base", "group_size", "is_representative"])
        w.writeheader()
        for b in sorted(reps):
            r = rows[reps[b]]
            w.writerow({
                "path": r["path"], "md5": r["md5"], "split": r["split"],
                "species_label": r["species_label"], "roast_label": r["roast_label"],
                "base": b, "group_size": len(by_base[b]), "is_representative": 1,
            })
    print(f"Manifest dedup  : {out2} ({len(reps)} baris)")

    print("\nPer split (dedup):")
    for s in ["train", "valid", "test"]:
        print(f"  {s:<6} {sum(1 for r in rep_rows if r['split'] == s)}")
    print("Per roast (dedup):")
    for k, v in sorted(Counter(roast).items()):
        print(f"  {k:<8} {v}")
    print("Per species (dedup):")
    for k, v in sorted(Counter(species).items()):
        print(f"  {k:<8} {v}")


if __name__ == "__main__":
    main()
