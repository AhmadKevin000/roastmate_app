#!/usr/bin/env python3
"""Push notebook ke Kaggle (dengan dataset sources) lewat Kaggle CLI.

Catatan penting soal API Kaggle:
  REST `POST /api/v1/kernels/push` versi lama menerima field `id` berisi
  "user/slug". API sekarang memisahkan `id` (integer) dan `slug` (string),
  jadi mengirim `id` sebagai "user/slug" ditolak dengan
  "Could not convert string to integer ... Path 'id'".
  Kaggle CLI sudah menangani ini dengan benar, jadi kita pakai CLI.

Metadata ditulis ke `kernel-metadata.json` di folder staging, lalu
`kaggle kernels push -p <folder>` dijalankan.

Token dibaca dari env `KAGGLE_API_TOKEN` (atau KAGGLE_MCP_TOKEN).
JANGAN menulis token ke file repo mana pun.

Contoh:
  KAGGLE_API_TOKEN=$(grep -o 'KGAT_[A-Za-z0-9]*' ~/.zshrc | head -1) \\
    python3 ml/scripts/kaggle_push_notebook.py \\
      --notebook ml/notebooks/roast_classification_exp002.ipynb \\
      --title "Roastmate Roast Classification EXP-002" \\
      --slug roastmate-roast-classification-exp002 \\
      --datasets ahmadkevinmalikz/roastmate-ds003-dedup --wait
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_KAGGLE = "/private/var/folders/70/xs_n7dt96vjfq5n_clt3pn5m0000gn/T/opencode/kaggle-venv/bin/kaggle"


def kaggle_bin():
    found = shutil.which("kaggle")
    if found:
        return found
    if Path(DEFAULT_KAGGLE).is_file():
        return DEFAULT_KAGGLE
    sys.exit("CLI `kaggle` tidak ditemukan. Install: pip install kaggle")


def env_with_token():
    env = dict(os.environ)
    token = env.get("KAGGLE_API_TOKEN") or env.get("KAGGLE_MCP_TOKEN") or env.get("KAGGLE_KEY")
    if not token:
        sys.exit("Token tidak ada: set KAGGLE_API_TOKEN")
    env["KAGGLE_API_TOKEN"] = token
    return env


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--notebook", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--slug", required=True)
    ap.add_argument("--username", default="ahmadkevinmalikz")
    ap.add_argument("--datasets", nargs="*", default=[])
    ap.add_argument("--stage", default="ml/data/kaggle_kernel")
    ap.add_argument("--no-gpu", action="store_true")
    ap.add_argument("--wait", action="store_true")
    args = ap.parse_args()

    nb = Path(args.notebook)
    if not nb.is_file():
        sys.exit(f"Notebook tidak ada: {nb}")

    stage = Path(args.stage)
    if stage.exists():
        shutil.rmtree(stage)
    stage.mkdir(parents=True)

    code_file = nb.name
    shutil.copy2(nb, stage / code_file)

    meta = {
        "id": f"{args.username}/{args.slug}",
        "title": args.title,
        "code_file": code_file,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": not args.no_gpu,
        "enable_internet": True,
        "dataset_sources": args.datasets,
        "competition_sources": [],
        "kernel_sources": [],
        "model_sources": [],
        "keywords": [],
        "machine_shape": "NvidiaTeslaT4",
    }
    (stage / "kernel-metadata.json").write_text(json.dumps(meta, indent=2) + "\n")

    print(f"Push {meta['id']}")
    print(f"  title    : {args.title}")
    print(f"  datasets : {args.datasets or '(none)'}")
    print(f"  gpu      : {meta['enable_gpu']}")
    print(f"  stage    : {stage}")

    r = subprocess.run(
        [kaggle_bin(), "kernels", "push", "-p", str(stage)],
        env=env_with_token(), text=True, capture_output=True,
    )
    print(r.stdout.strip())
    if r.returncode != 0:
        sys.exit(f"PUSH GAGAL:\n{r.stderr.strip()}")

    if args.wait:
        print("\nMenunggu sesi selesai (polling)...")
        for _ in range(360):
            s = subprocess.run(
                [kaggle_bin(), "kernels", "status", f"{args.username}/{args.slug}"],
                env=env_with_token(), text=True, capture_output=True,
            )
            state = s.stdout.strip()
            print(f"  status: {state}")
            if state in ("complete", "error", "cancelled"):
                break
            time.sleep(30)


if __name__ == "__main__":
    main()
