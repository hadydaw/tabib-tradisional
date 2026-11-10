#!/usr/bin/env bash
# Tangkapan layar visual placeholder lewat xvfb + Mesa (renderer perangkat lunak). Informatif:
# kegagalan di sini tidak menggagalkan build. Hasil ke build/logs/shots dan dicetak sebagai
# base64 di log agar bisa diperiksa tanpa mengunduh artifact.
set -uo pipefail
OUT="$PWD/build/logs/shots"; mkdir -p "$OUT"
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq xvfb libgl1 libgl1-mesa-dri libglx-mesa0 libxcursor1 libxinerama1 libxrandr2 libxi6 libasound2t64 >/dev/null 2>&1 || echo "peringatan: pemasangan paket tidak sempurna"
export SHOT_DIR="$OUT"
timeout 240 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 --resolution 1280x720 --script res://tests/visual/capture.gd 2>&1 | tail -40
ls -la "$OUT" || true
for f in "$OUT"/*.jpg; do
  [ -f "$f" ] || continue
  echo "SHOT-BEGIN $(basename "$f") $(stat -c%s "$f")"
  base64 -w 3000 "$f"
  echo "SHOT-END"
done
