#!/usr/bin/env bash
# Publikasi dataset privat hasil dedup ke Kaggle (Langkah 5).
#
# Membuat staging dir berisi:
#   ds003_dedup/          struktur train/val/test
#   calib/                kalibrasi INT8 (hanya dari split train)
#   split.csv             sumber kebenaran split
#   calib_manifest.csv    bukti asal gambar kalibrasi
#
# Lalu membuat/memperbarui dataset privat `roastmate-ds003-dedup`.
# Token dibaca dari env KAGGLE_MCP_TOKEN; JANGAN commit token ke repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

USER="${KAGGLE_USER:-ahmadkevinmalikz}"
SLUG="${KAGGLE_DATASET_SLUG:-roastmate-ds003-dedup}"
STAGE="${STAGE:-ml/data/kaggle_upload}"
TOKEN="${KAGGLE_MCP_TOKEN:-$(grep -o 'KGAT_[A-Za-z0-9]*' ~/.zshrc 2>/dev/null | head -1 || true)}"
KAGGLE_BIN="${KAGGLE_BIN:-$(command -v kaggle || echo /private/var/folders/70/xs_n7dt96vjfq5n_clt3pn5m0000gn/T/opencode/kaggle-venv/bin/kaggle)}"

if [[ -z "$TOKEN" ]]; then
  echo "Token Kaggle tidak tersedia (set KAGGLE_MCP_TOKEN)." >&2
  exit 1
fi
if [[ ! -d ml/data/ds003_dedup || ! -d ml/data/calib ]]; then
  echo "ml/data/ds003_dedup atau ml/data/calib belum ada. Jalankan materialize.py dulu." >&2
  exit 1
fi

echo "Staging -> $STAGE"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R ml/data/ds003_dedup "$STAGE/ds003_dedup"
cp -R ml/data/calib "$STAGE/calib"
cp ml/registries/split.csv "$STAGE/split.csv"
cp ml/data/calib_manifest.csv "$STAGE/calib_manifest.csv"

cat > "$STAGE/dataset-metadata.json" <<EOF
{
  "title": "Roastmate DS003 Dedup",
  "id": "$USER/$SLUG",
  "licenses": [{"name": "CC0-1.0"}],
  "description": "DS003 (gpiosenka/coffee-bean-dataset-resized-224-x-224) setelah dedup MD5 + split grup-aware 70/15/15. Termasuk folder kalibrasi INT8 yang hanya berasal dari split train."
}
EOF

echo "Ukuran staging: $(du -sh "$STAGE" | cut -f1)"
export KAGGLE_USERNAME="$USER"
export KAGGLE_KEY="$TOKEN"

if "$KAGGLE_BIN" datasets list -m --csv 2>/dev/null | tail -n +2 | cut -d, -f1 | grep -qx "$USER/$SLUG"; then
  echo "Dataset sudah ada -> buat versi baru"
  "$KAGGLE_BIN" datasets version -p "$STAGE" -m "dedup 1194 unik + split grup-aware + calib train-only" --dir-mode zip
else
  echo "Dataset belum ada -> buat baru"
  "$KAGGLE_BIN" datasets create -p "$STAGE" --dir-mode zip
fi

echo "Selesai. Dataset: https://www.kaggle.com/datasets/$USER/$SLUG"
