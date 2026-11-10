#!/usr/bin/env python3
"""Deteksi near-duplicate lapis kedua pakai embedding dari backbone pretrained.

Backbone: torchvision ResNet-18 (ImageNet, TANPA fine-tuning). Fitur diambil dari
output avgpool (512-d), dinormalisasi L2, lalu kemiripan dihitung dengan cosine
similarity.

Alur:
  1. Baca ml/data/manifest.csv, ambil baris keep=1 (gambar unik hasil dedup MD5).
  2. Hitung embedding -> ml/data/embeddings.npy + ml/data/embeddings_index.csv
  3. Cari pasangan dengan cosine similarity >= ambang (default 0.95).
     -> ml/data/near_dup_candidates.csv
  4. Gabungkan pasangan jadi grup (union-find), tulis ulang manifest + kolom group_id.
  5. Tulis ml/data/near_dup_sample.csv (30 pasang >= ambang, 30 pasang < ambang,
     seed 42) untuk inspeksi manual.

Catatan: 30 pasang "di bawah ambang" diambil dari 1000 pasangan bersimilaritas
tertinggi yang masih < ambang, supaya inspeksi lebih berguna (pasangan acak murni
biasanya jelas berbeda dan tidak informatif).

Pakai venv: ml/.venv/bin/python ml/scripts/embed_dedup.py
"""

import argparse
import csv
import json
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import torch
import torchvision
from PIL import Image
from torchvision import transforms


def load_manifest(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def write_manifest(path, rows, fieldnames):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def build_model(backbone="resnet18"):
    if backbone == "resnet18":
        weights = torchvision.models.ResNet18_Weights.IMAGENET1K_V1
        model = torchvision.models.resnet18(weights=weights)
        dim = 512
    elif backbone == "resnet50":
        weights = torchvision.models.ResNet50_Weights.IMAGENET1K_V2
        model = torchvision.models.resnet50(weights=weights)
        dim = 2048
    elif backbone == "mobilenet_v3_small":
        weights = torchvision.models.MobileNet_V3_Small_Weights.IMAGENET1K_V1
        model = torchvision.models.mobilenet_v3_small(weights=weights)
        dim = 576
    else:
        sys.exit(f"backbone tidak dikenal: {backbone}")
    model.fc = torch.nn.Identity()
    model.eval()
    return model, dim


def make_transform(img_size=224):
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(img_size),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])


@torch.no_grad()
def compute_embeddings(model, tfm, root, rel_paths, batch_size=32):
    feats = []
    for i in range(0, len(rel_paths), batch_size):
        chunk = rel_paths[i:i + batch_size]
        imgs = []
        for rel in chunk:
            with Image.open(root / rel) as im:
                imgs.append(tfm(im.convert("RGB")))
        batch = torch.stack(imgs)
        out = model(batch)
        feats.append(out.cpu().numpy().astype(np.float32))
        if (i // batch_size) % 10 == 0:
            print(f"  embedding {i + len(chunk)}/{len(rel_paths)}", flush=True)
    emb = np.concatenate(feats, axis=0)
    norms = np.linalg.norm(emb, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    return emb / norms


class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))

    def find(self, x):
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="ml/data/manifest.csv")
    ap.add_argument("--dataset-dir", default="ml/data/ds003")
    ap.add_argument("--outdir", default="ml/data")
    ap.add_argument("--threshold", type=float, default=0.95)
    ap.add_argument("--backbone", default="resnet18")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)

    root = Path(args.dataset_dir)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    rows = load_manifest(args.manifest)
    kept = [r for r in rows if r["keep"] == "1"]
    print(f"Manifest       : {args.manifest}")
    print(f"Total baris    : {len(rows)} | keep=1: {len(kept)}")

    rel_paths = [r["path"] for r in kept]
    classes = [r["class"] for r in kept]

    model, dim = build_model(args.backbone)
    tfm = make_transform()
    print(f"Backbone       : {args.backbone} ({dim}-d, ImageNet, no fine-tune)")
    emb = compute_embeddings(model, tfm, root, rel_paths)
    np.save(outdir / "embeddings.npy", emb)
    with open(outdir / "embeddings_index.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["row", "path", "class"])
        for i, (p, c) in enumerate(zip(rel_paths, classes)):
            w.writerow([i, p, c])
    print(f"Embeddings     : {emb.shape} -> {outdir / 'embeddings.npy'}")

    n = len(rel_paths)
    sim = emb @ emb.T
    iu = np.triu_indices(n, k=1)
    sims = sim[iu]
    print(f"Pasangan total : {len(sims):,}")
    print(f"Similarity     : max={sims.max():.4f} mean={sims.mean():.4f}")

    for th in (0.90, 0.95, 0.98, 0.99, 0.995):
        c = int((sims >= th).sum())
        print(f"  pasangan >= {th}: {c}")

    mask = sims >= args.threshold
    ai, bi = iu[0][mask], iu[1][mask]
    print(f"\nAmbang         : {args.threshold} -> {len(ai)} pasangan")

    with open(outdir / "near_dup_candidates.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["path_a", "path_b", "similarity", "label_a", "label_b"])
        order = np.argsort(-sims[mask]) if len(ai) else []
        for k in order:
            a, b = int(ai[k]), int(bi[k])
            w.writerow([rel_paths[a], rel_paths[b], f"{sim[a, b]:.6f}", classes[a], classes[b]])

    uf = UnionFind(n)
    cross_class_pairs = 0
    for k in range(len(ai)):
        a, b = int(ai[k]), int(bi[k])
        if classes[a] != classes[b]:
            cross_class_pairs += 1
        uf.union(a, b)
    comp = [uf.find(i) for i in range(n)]
    roots = sorted(set(comp))
    root_to_gid = {r: f"NG{i:04d}" for i, r in enumerate(roots, start=1)}
    gids = [root_to_gid[c] for c in comp]
    print(f"Grup near-dup  : {len(roots)} (dari {n} gambar)")
    print(f"Pasangan beda kelas: {cross_class_pairs}")

    sizes = Counter(Counter(gids).values())
    print(f"Sebaran ukuran grup: {dict(sorted(sizes.items()))}")
    merged_imgs = sum(c for c in Counter(gids).values() if c > 1)
    print(f"Gambar di grup >1 : {merged_imgs}")

    # tulis ulang manifest + group_id
    gid_by_path = {p: g for p, g in zip(rel_paths, gids)}
    rep_gid_by_md5 = {}
    for r in kept:
        rep_gid_by_md5[r["md5"]] = gid_by_path[r["path"]]
    for r in rows:
        if r["keep"] == "1":
            r["group_id"] = gid_by_path[r["path"]]
        else:
            r["group_id"] = rep_gid_by_md5.get(r["md5"], "NG0000")
    fields = ["path", "md5", "class", "dup_group_id", "keep", "group_id"]
    write_manifest(args.manifest, rows, fields)
    print(f"Manifest ditulis ulang + kolom group_id: {args.manifest}")

    # sampel inspeksi
    above = np.where(mask)[0]
    below = np.where(~mask)[0]
    rng = np.random.default_rng(args.seed)
    pick_above = rng.choice(above, size=min(30, len(above)), replace=False) if len(above) else []
    if len(below):
        top_below = below[np.argsort(-sims[below])][:1000]
        pick_below = rng.choice(top_below, size=min(30, len(top_below)), replace=False)
    else:
        pick_below = []
    with open(outdir / "near_dup_sample.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["bucket", "path_a", "path_b", "similarity", "label_a", "label_b"])
        for k in pick_above:
            a, b = int(iu[0][k]), int(iu[1][k])
            w.writerow(["above", rel_paths[a], rel_paths[b], f"{sim[a, b]:.6f}", classes[a], classes[b]])
        for k in pick_below:
            a, b = int(iu[0][k]), int(iu[1][k])
            w.writerow(["below", rel_paths[a], rel_paths[b], f"{sim[a, b]:.6f}", classes[a], classes[b]])
    print(f"Sampel inspeksi: {outdir / 'near_dup_sample.csv'} ({len(pick_above)} above, {len(pick_below)} below)")


if __name__ == "__main__":
    main()
