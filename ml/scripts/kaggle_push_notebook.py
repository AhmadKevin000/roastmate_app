#!/usr/bin/env python3
"""Push notebook ke Kaggle lewat REST API v1, dengan datasetDataSources.

Kenapa lewat REST? MCP `save_notebook` MENGABAIKAN `datasetDataSources`, jadi
dataset tidak pernah ter-attach. Push lewat REST berhasil melakukannya.

Token dibaca dari env `KAGGLE_MCP_TOKEN` (atau `KAGGLE_KEY`).
JANGAN menulis token ke file repo mana pun.

Contoh:
  KAGGLE_MCP_TOKEN=$(grep -o 'KGAT_[A-Za-z0-9]*' ~/.zshrc | head -1) \\
    python3 ml/scripts/kaggle_push_notebook.py \\
      --notebook ml/notebooks/roast_classification_exp002.ipynb \\
      --title "Roastmate Roast Classification EXP-002" \\
      --slug roastmate-roast-classification-exp002 \\
      --datasets ahmadkevinmalikz/roastmate-ds003-dedup
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://www.kaggle.com/api/v1"


def request(url, token, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip().startswith(("{", "[")) else raw)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:2000]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--notebook", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--slug", required=True)
    ap.add_argument("--username", default="ahmadkevinmalikz")
    ap.add_argument("--datasets", nargs="*", default=[])
    ap.add_argument("--no-gpu", action="store_true")
    ap.add_argument("--wait", action="store_true")
    args = ap.parse_args()

    token = os.environ.get("KAGGLE_MCP_TOKEN") or os.environ.get("KAGGLE_KEY")
    if not token:
        sys.exit("Token tidak ada: set KAGGLE_MCP_TOKEN")

    text = Path(args.notebook).read_text()
    payload = {
        "id": f"{args.username}/{args.slug}",
        "newTitle": args.title,
        "text": text,
        "language": "python",
        "kernelType": "notebook",
        "isPrivate": True,
        "enableGpu": not args.no_gpu,
        "enableInternet": True,
        "machineShape": "NvidiaTeslaT4",
        "datasetDataSources": args.datasets,
        "kernelExecutionType": "SaveAndRunAll",
    }
    print(f"Push {payload['id']}")
    print(f"  title    : {args.title}")
    print(f"  datasets : {args.datasets or '(none)'}")
    print(f"  gpu      : {payload['enableGpu']}")

    status, resp = request(f"{API}/kernels/push", token, "POST", payload)
    print(f"  HTTP {status}")
    if status >= 300:
        sys.exit(f"PUSH GAGAL: {resp}")
    print(f"  resp: {resp if isinstance(resp, str) else json.dumps(resp)[:300]}")

    # verifikasi datasetDataSources benar-benar terpasang
    time.sleep(5)
    st, meta = request(f"{API}/kernels/pull?userName={args.username}&kernelSlug={args.slug}", token)
    if st == 200 and isinstance(meta, dict):
        got = meta.get("datasetDataSources") or meta.get("metadata", {}).get("datasetDataSources")
        print(f"\nVerifikasi pull: datasetDataSources = {got}")
        if args.datasets and got != args.datasets:
            print(f"  PERINGATAN: diharapkan {args.datasets}")
    else:
        print(f"\nPull gagal (HTTP {st}): {meta}")

    if args.wait:
        for _ in range(240):
            st, s = request(
                f"{API}/kernels/status?userName={args.username}&kernelSlug={args.slug}", token
            )
            state = s.get("status") if isinstance(s, dict) else s
            print(f"  status: {state}")
            if state in ("complete", "error", "cancelled"):
                break
            time.sleep(30)


if __name__ == "__main__":
    main()
