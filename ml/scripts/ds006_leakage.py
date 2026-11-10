#!/usr/bin/env python3
"""Cek kebocoran DS006 terhadap DS003 (Langkah 3).

Membandingkan 583 representan DS006 (hasil dedup basis, manifest_dedup.csv)
dengan SELURUH 1600 gambar DS003 (train/ dan test/), dua lapis:

  1. MD5 identik.
  2. Embedding ResNet-18 ImageNet tanpa fine-tune (identik embed_dedup.py),
     cosine similarity. Pasangan di atas ambang (default 0.95) dianggap bocor.

Output:
  ml/data/ds006/leakage_report.csv
    kolom: path_ds006, path_ds003, md5_match, similarity, label_ds006, label_ds003
    (satu baris per gambar DS006 = tetangga DS003 paling mirip; plus semua pasangan MD5)
  ml/data/ds006/manifest_clean.csv
    DS006 tanpa gambar yang bocor. kolom sama seperti manifest_dedup.csv.

Skrip GAGAL bila >20% gambar DS006 bocor ke DS003.
"""

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path

import numpy as np
import torch
import torchvision
from PIL import Image
from torchvision import transforms

DS003_ROOT = Path("ml/data/ds003")


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
def compute_embeddings(model, tfm, paths, batch_size=32, tag=""):
    feats = []
    for i in range(0, len(paths), batch_size):
        chunk = paths[i:i + batch_size]
        imgs = []
        for p in chunk:
            with Image.open(p) as im:
                imgs.append(tfm(im.convert("RGB")))
        feats.append(model(torch.stack(imgs)).cpu().numpy().astype(np.float32))
        if (i // batch_size) % 10 == 0:
            print(f"  {tag} embedding {i + len(chunk)}/{len(paths)}", flush=True)
    emb = np.concatenate(feats, axis=0)
    norms = np.linalg.norm(emb, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    return emb / norms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ds006", default="ml/data/ds006/manifest_dedup.csv")
    ap.add_argument("--ds003", default="ml/data/ds003_manifest.csv")
    ap.add_argument("--outdir", default="ml/data/ds006")
    ap.add_argument("--threshold", type=float, default=0.95)
    ap.add_argument("--max-leak-frac", type=float, default=0.20)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    torch.manual_seed(args.seed)
    np.random.seed(args.seed)

    with open(args.ds006, newline="") as f:
        d6 = list(csv.DictReader(f))
    with open(args.ds003, newline="") as f:
        d3 = list(csv.DictReader(f))
    print(f"DS006 (dedup)  : {len(d6)} | DS003: {len(d3)}")

    d6_paths = [r["path"] for r in d6]
    d3_paths = [str(DS003_ROOT / r["path"]) for r in d3]

    # ---------- MD5 ----------
    md5_to_d3 = {}
    for i, r in enumerate(d3):
        md5_to_d3.setdefault(r["md5"], []).append(i)
    md5_hits = {}
    for i, r in enumerate(d6):
        if r["md5"] in md5_to_d3:
            md5_hits[i] = md5_to_d3[r["md5"]]
    print(f"MD5 cocok      : {len(md5_hits)} gambar DS006 punya kembar identik di DS003")

    # ---------- embedding ----------
    model = build_model()
    tfm = make_transform()
    print("Menghitung embedding DS006 ...")
    e6 = compute_embeddings(model, tfm, d6_paths, tag="DS006")
    print("Menghitung embedding DS003 ...")
    e3 = compute_embeddings(model, tfm, d3_paths, tag="DS003")

    sim = e6 @ e3.T                      # (583, 1600)
    best_idx = sim.argmax(axis=1)
    best_val = sim[np.arange(len(d6)), best_idx]

    # ---------- laporan ----------
    out_rows = []
    for i, r in enumerate(d6):
        j = int(best_idx[i])
        md5m = 1 if i in md5_hits else 0
        out_rows.append({
            "path_ds006": r["path"], "path_ds003": d3[j]["path"],
            "md5_match": md5m, "similarity": f"{best_val[i]:.6f}",
            "label_ds006": r["roast_label"], "label_ds003": d3[j]["label"],
        })
    # tambahan: semua pasangan MD5 (bukan hanya best)
    for i, js in md5_hits.items():
        for j in js:
            out_rows.append({
                "path_ds006": d6[i]["path"], "path_ds003": d3[j]["path"],
                "md5_match": 1, "similarity": "1.000000",
                "label_ds006": d6[i]["roast_label"], "label_ds003": d3[j]["label"],
            })

    rep = Path(args.outdir) / "leakage_report.csv"
    with open(rep, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path_ds006", "path_ds003", "md5_match",
                                          "similarity", "label_ds006", "label_ds003"])
        w.writeheader()
        w.writerows(out_rows)
    print(f"\nLaporan leakage: {rep} ({len(out_rows)} baris)")

    # ---------- ringkasan ----------
    print(f"\nSimilarity maksimum per gambar DS006:")
    print(f"  max={best_val.max():.4f} mean={best_val.mean():.4f} min={best_val.min():.4f}")
    for th in (0.99, 0.98, 0.97, 0.96, 0.95, 0.93, 0.90):
        print(f"  gambar dengan tetangga DS003 >= {th}: {int((best_val >= th).sum())}")

    leaked_md5 = set(md5_hits.keys())
    leaked_sim = set(int(i) for i in np.where(best_val >= args.threshold)[0])
    leaked = leaked_md5 | leaked_sim
    print(f"\nBocor (MD5 atau similarity >= {args.threshold}): {len(leaked)} "
          f"({100 * len(leaked) / len(d6):0.1f}%)")
    print(f"  via MD5        : {len(leaked_md5)}")
    print(f"  via similarity : {len(leaked_sim)}")
    print(f"  label DS006 yang bocor: {dict(sorted(Counter(d6[i]['roast_label'] for i in leaked).items()))}")

    if len(leaked) / len(d6) > args.max_leak_frac:
        sys.exit(f"\nBERHENTI: {100 * len(leaked) / len(d6):0.1f}% gambar DS006 bocor "
                 f"(> {100 * args.max_leak_frac:0.0f}%). Perlu keputusan user.")

    # ---------- manifest_clean ----------
    clean = [r for i, r in enumerate(d6) if i not in leaked]
    out = Path(args.outdir) / "manifest_clean.csv"
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(d6[0].keys()))
        w.writeheader()
        w.writerows(clean)
    print(f"\nManifest bersih : {out} ({len(clean)} baris)")
    print(f"  per split : {dict(sorted(Counter(r['split'] for r in clean).items()))}")
    print(f"  per roast : {dict(sorted(Counter(r['roast_label'] for r in clean).items()))}")
    print(f"  per species: {dict(sorted(Counter(r['species_label'] for r in clean).items()))}")


if __name__ == "__main__":
    main()
