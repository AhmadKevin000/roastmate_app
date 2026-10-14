#!/usr/bin/env python3
"""Audit dataset klasifikasi gambar: duplikat persis, near-duplicate (pHash warna),
distribusi kelas, dan potensi kebocoran train/test.

pHash dihitung per kanal R,G,B (192 bit) supaya perbedaan WARNA ikut tertangkap.
Ini penting untuk dataset roast, di mana warna adalah fitur utama.

Contoh pakai:
    python3 ml/scripts/audit_dataset.py ml/data/ds003 \
        --label-map '{"dark":"Dark","green":"Green","light":"Light","medium":"Medium"}'
"""

import argparse
import hashlib
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.fft import dctn
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components

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


def phash_channel(arr, hash_size=8):
    dct = dctn(arr, norm="ortho")
    low = dct[:hash_size, :hash_size]
    med = np.median(low)
    return (low > med).flatten().astype(np.uint8)


def phash_color(path: Path, hash_size=8, factor=4):
    """pHash per kanal R,G,B -> 3*hash_size^2 bit."""
    size = hash_size * factor
    with Image.open(path) as im:
        im = im.convert("RGB").resize((size, size), Image.LANCZOS)
        rgb = np.asarray(im, dtype=np.float64)
    bits = np.concatenate([phash_channel(rgb[:, :, c], hash_size) for c in range(3)])
    return bits


def bits_to_words(bits: np.ndarray, words=3, word_bits=64):
    out = []
    for w in range(words):
        v = np.uint64(0)
        for b in bits[w * word_bits:(w + 1) * word_bits]:
            v = (v << np.uint64(1)) | np.uint64(int(b))
        out.append(v)
    return out


def connected_groups(n, dist, threshold):
    iu = np.triu_indices(n, k=1)
    close = dist[iu] <= threshold
    if not close.any():
        return np.arange(n)
    m = coo_matrix((np.ones(int(close.sum()), dtype=np.uint8), (iu[0][close], iu[1][close])), shape=(n, n))
    _, labels = connected_components(m, directed=False)
    return labels


def group_stats(records, labels):
    groups = defaultdict(list)
    for i, g in enumerate(labels):
        groups[int(g)].append(i)
    multi = {g: idx for g, idx in groups.items() if len(idx) > 1}
    return groups, multi


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dataset_dir")
    ap.add_argument("--label-map", default=None, help="JSON mapping folder->label")
    ap.add_argument("--threshold", type=int, default=24, help="ambang Hamming pHash 192-bit")
    ap.add_argument("--top-examples", type=int, default=8)
    ap.add_argument("--write-manifest", default=None, help="tulis CSV manifest hasil dedup")
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
        label = folder
        if label_map:
            label = label_map.get(folder.lower().replace(" ", "_"), folder)
        split = parts[0] if len(parts) >= 2 else "(root)"
        records.append({"path": str(rel), "folder": folder, "label": label, "split": split})
    n = len(records)

    print("=== RINGKASAN DATASET ===")
    print(f"Total gambar : {n}")
    print(f"Per kelas    : {dict(sorted(Counter(r['label'] for r in records).items()))}")
    print(f"Per split    : {dict(sorted(Counter(r['split'] for r in records).items()))}")
    print("\n--- split x kelas ---")
    for (s, l), c in sorted(Counter((r["split"], r["label"]) for r in records).items()):
        print(f"  {s:>10} / {l:<10} : {c}")

    print("\n=== UKURAN GAMBAR (sampel 200) ===")
    sizes = Counter()
    for r in records[:200]:
        with Image.open(root / r["path"]) as im:
            sizes[im.size] += 1
    for sz, c in sizes.most_common(6):
        print(f"  {sz[0]}x{sz[1]} : {c}")

    # ---------- duplikat persis ----------
    print("\n=== DUPLIKAT PERSIS (MD5) ===")
    for r in records:
        r["md5"] = md5_of(root / r["path"])
    by_md5 = defaultdict(list)
    for i, r in enumerate(records):
        by_md5[r["md5"]].append(i)
    dup = {h: idx for h, idx in by_md5.items() if len(idx) > 1}
    n_dup_files = sum(len(v) for v in dup.values())
    print(f"Grup duplikat persis : {len(dup)}")
    print(f"File terlibat        : {n_dup_files} ({n_dup_files/n*100:.1f}% dari total)")

    split_combo = Counter()
    for idx in dup.values():
        split_combo[tuple(sorted({records[i]['split'] for i in idx}))] += 1
    print("Komposisi split grup duplikat:")
    for combo, c in sorted(split_combo.items(), key=lambda kv: -kv[1]):
        print(f"  {combo}: {c} grup")

    # berapa gambar test yang punya kembaran persis di train
    train_md5 = {records[i]["md5"] for i in range(n) if records[i]["split"] == "train"}
    test_idx = [i for i in range(n) if records[i]["split"] == "test"]
    leaked = [i for i in test_idx if records[i]["md5"] in train_md5]
    print(f"Gambar test yg punya duplikat persis di train : {len(leaked)}/{len(test_idx)} "
          f"({len(leaked)/max(len(test_idx),1)*100:.1f}%)")

    # ---------- near-duplicate ----------
    print("\n=== NEAR-DUPLICATE (pHash WARNA 192-bit) ===")
    words = np.array([bits_to_words(phash_color(root / r["path"])) for r in records], dtype=np.uint64)  # (n,3)
    xor = np.bitwise_xor(words[:, None, :], words[None, :, :])          # (n,n,3)
    dist = np.bitwise_count(xor).sum(axis=2).astype(np.uint16)          # (n,n)
    np.fill_diagonal(dist, np.uint16(192))

    print("Sweep ambang:")
    print(f"  {'th':>3} | {'grup':>5} | {'gambar':>6} | {'lintas-split':>12} | {'konflik-label':>13}")
    for th in (4, 6, 8, 10, 12, 18, 24, 30, 36):
        lab = connected_groups(n, dist, th)
        _, multi = group_stats(records, lab)
        nimg = sum(len(v) for v in multi.values())
        ncross = sum(1 for v in multi.values() if len({records[i]['split'] for i in v}) > 1)
        nconf = sum(1 for v in multi.values() if len({records[i]['label'] for i in v}) > 1)
        print(f"  {th:>3} | {len(multi):>5} | {nimg:>6} ({nimg/n*100:4.1f}%) | {ncross:>12} | {nconf:>13}")

    labels_comp = connected_groups(n, dist, args.threshold)
    groups, multi = group_stats(records, labels_comp)
    n_in_multi = sum(len(v) for v in multi.values())
    print(f"\nAmbang terpakai = {args.threshold}")
    print(f"Total grup            : {len(groups)}")
    print(f"Grup >1 gambar        : {len(multi)}")
    print(f"Gambar dalam grup     : {n_in_multi} ({n_in_multi/n*100:.1f}%)")
    print(f"Sebaran ukuran grup   : {dict(sorted(Counter(len(v) for v in groups.values()).items()))}")

    cross = {g: idx for g, idx in multi.items() if len({records[i]['split'] for i in idx}) > 1}
    cross_imgs = sum(len(v) for v in cross.values())
    conflict = {g: idx for g, idx in multi.items() if len({records[i]['label'] for i in idx}) > 1}
    print(f"Grup lintas train/test: {len(cross)} grup, {cross_imgs} gambar")
    print(f"Grup >1 label         : {len(conflict)} grup")

    print("\n--- contoh grup besar (warna) ---")
    for g, idx in sorted(multi.items(), key=lambda kv: -len(kv[1]))[:args.top_examples]:
        labs = Counter(records[i]["label"] for i in idx)
        splits = Counter(records[i]["split"] for i in idx)
        print(f"  grup {g}: {len(idx)} gambar | kelas={dict(labs)} | split={dict(splits)}")
        for i in idx[:3]:
            print(f"      {records[i]['path']}")
        if len(idx) > 3:
            print(f"      ... +{len(idx)-3} lagi")

    print("\n=== KESIMPULAN ===")
    print(f"1. Duplikat persis     : {len(dup)} grup / {n_dup_files} file")
    print(f"2. Test ter-leak (MD5) : {len(leaked)}/{len(test_idx)} gambar test punya kembaran di train")
    print(f"3. Near-dup (warna)    : {len(multi)} grup / {n_in_multi} gambar @ ambang {args.threshold}")
    print(f"4. Lintas train/test   : {len(cross)} grup")
    print(f"5. Konflik label       : {len(conflict)} grup")
    n_unique = len(by_md5)
    print(f"6. Gambar unik (dedup) : {n_unique} dari {n} ({n_unique/n*100:.1f}%)")

    if args.write_manifest:
        seen = {}
        kept = 0
        with open(args.write_manifest, "w") as f:
            f.write("path,label,split,md5,is_duplicate\n")
            for i, r in enumerate(records):
                first = seen.setdefault(r["md5"], i)
                is_dup = "0" if first == i else "1"
                if first == i:
                    kept += 1
                f.write(f"{r['path']},{r['label']},{r['split']},{r['md5']},{is_dup}\n")
        print(f"\nManifest ditulis ke {args.write_manifest} ({kept} file unik, {n - kept} duplikat)")


if __name__ == "__main__":
    main()
