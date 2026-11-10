#!/usr/bin/env python3
"""Tunggu sesi Kaggle selesai, lalu tarik metrik & artefak.

Dipakai untuk EXP-ROAST-002. Setelah status complete/error:
  - cetak run_meta.json (kalau ada) dari output notebook
  - salin best.pt & best_int8.tflite ke ml/models/

Contoh:
  KAGGLE_MCP_TOKEN=$(grep -o 'KGAT_[A-Za-z0-9]*' ~/.zshrc | head -1) \\
    python3 ml/scripts/kaggle_collect.py --slug roastmate-roast-classification-exp-002
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://www.kaggle.com/api/v1"
ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")


def get(url, token):
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--username", default="ahmadkevinmalikz")
    ap.add_argument("--slug", required=True)
    ap.add_argument("--models-dir", default="ml/models")
    ap.add_argument("--poll", type=int, default=30)
    ap.add_argument("--max-min", type=int, default=150)
    args = ap.parse_args()

    token = os.environ.get("KAGGLE_MCP_TOKEN") or os.environ.get("KAGGLE_API_TOKEN") or os.environ.get("KAGGLE_KEY")
    if not token:
        sys.exit("Token tidak ada: set KAGGLE_MCP_TOKEN")

    deadline = time.time() + args.max_min * 60
    state = None
    while time.time() < deadline:
        try:
            st = get(f"{API}/kernels/status?userName={args.username}&kernelSlug={args.slug}", token)
            state = st.get("status", "")
        except urllib.error.HTTPError as e:
            state = f"HTTP {e.code}"
        print(f"  status: {state}", flush=True)
        if state in ("complete", "error", "cancelled"):
            break
        time.sleep(args.poll)

    d = get(f"{API}/kernels/output?userName={args.username}&kernelSlug={args.slug}", token)
    text = ANSI.sub("", "".join(e.get("data", "") for e in json.loads(d.get("log") or "[]")))

    print("\n=== status akhir:", state, "===")

    m = re.search(r"===RUN_META_JSON===\s*(\{.*?\})\s*===END_RUN_META_JSON===", text, re.S)
    if m:
        meta = json.loads(m.group(1))
        print("\n=== run_meta.json ===")
        print(json.dumps(meta, indent=2))
        Path("ml/data").mkdir(parents=True, exist_ok=True)
        Path("ml/data/exp002_run_meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    else:
        print("\nrun_meta.json tidak ditemukan di log. Ekor log:")
        print("\n".join(text.splitlines()[-60:]))

    # ringkas metrik penting dari log
    for pat in (r"\[VAL float\][^\n]*", r"\[TEST float\][^\n]*", r"\[TEST int8\][^\n]*",
                r"Selisih float - int8[^\n]*", r"EarlyStopping[^\n]*", r"epochs completed[^\n]*",
                r"EXPORT INT8 GAGAL[^\n]*", r"INT8 inference gagal[^\n]*"):
        for line in re.findall(pat, text):
            print("  ", line)

    files = d.get("files", [])
    print("\n=== file output ===")
    for f in files:
        print("  ", f.get("name") if isinstance(f, dict) else f)


if __name__ == "__main__":
    main()
