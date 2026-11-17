#!/usr/bin/env python3
"""Ambil log & output notebook Kaggle lewat REST API v1.

Contoh:
  KAGGLE_MCP_TOKEN=$(grep -o 'KGAT_[A-Za-z0-9]*' ~/.zshrc | head -1) \\
    python3 ml/scripts/kaggle_fetch_log.py \\
      --slug roastmate-roast-classification-exp-002 --tail 120
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

API = "https://www.kaggle.com/api/v1"
ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")


def get(url, token):
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()[:500]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--username", default="ahmadkevinmalikz")
    ap.add_argument("--slug", required=True)
    ap.add_argument("--tail", type=int, default=0, help="cetak N baris terakhir (0 = semua)")
    ap.add_argument("--grep", default=None, help="hanya baris yang cocok regex ini")
    args = ap.parse_args()

    token = os.environ.get("KAGGLE_MCP_TOKEN") or os.environ.get("KAGGLE_API_TOKEN") or os.environ.get("KAGGLE_KEY")
    if not token:
        sys.exit("Token tidak ada: set KAGGLE_MCP_TOKEN")

    st = get(f"{API}/kernels/status?userName={args.username}&kernelSlug={args.slug}", token)
    print("status:", st.get("status"))

    d = get(f"{API}/kernels/output?userName={args.username}&kernelSlug={args.slug}", token)
    events = json.loads(d.get("log") or "[]")
    text = ANSI.sub("", "".join(e.get("data", "") for e in events))
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if args.grep:
        lines = [ln for ln in lines if re.search(args.grep, ln)]
    if args.tail:
        lines = lines[-args.tail:]
    print("\n".join(lines))


if __name__ == "__main__":
    main()
