#!/usr/bin/env bash
# Validasi proyek: cek statis project.godot, impor, cek sintaks semua skrip, tes unit.
# Menulis log ke build/logs/. Keluar non-nol jika ada yang gagal.
set -uo pipefail

LOGS="build/logs"; mkdir -p "$LOGS"
FAIL=0

echo "== 1. Pemeriksaan statis project.godot =="
python3 tools/check_project.py game 2>&1 | tee "$LOGS/check_project.log" || FAIL=1

echo "== 1b. Uji parser kompatibilitas APK =="
python3 tools/check_apk_compat.py --selftest 2>&1 | tee "$LOGS/compat_selftest.log" || FAIL=1

echo "== 2. Impor proyek (membangun cache class dan resource) =="
godot --headless --path game --import 2>&1 | tee "$LOGS/import.log"
# Kegagalan parse/muat terlihat sebagai SCRIPT ERROR atau Parse Error pada log impor.
if grep -E "SCRIPT ERROR|Parse Error|Failed to load" "$LOGS/import.log"; then
  echo "GAGAL: ada error skrip/resource saat impor"; FAIL=1
fi

echo "== 3. Cek sintaks setiap skrip GDScript =="
: > "$LOGS/check_scripts.log"
while IFS= read -r f; do
  rel="res://${f#game/}"
  if out=$(godot --headless --path game --check-only --script "$rel" 2>&1); then
    echo "  OK    $rel" | tee -a "$LOGS/check_scripts.log"
  else
    echo "  GAGAL $rel" | tee -a "$LOGS/check_scripts.log"
    echo "$out" | tee -a "$LOGS/check_scripts.log"
    FAIL=1
  fi
done < <(find game -name '*.gd' -not -path 'game/.godot/*' | sort)

echo "== 4. Tes unit =="
godot --headless --path game --script res://tests/unit/run_tests.gd 2>&1 | tee "$LOGS/unit_tests.log"
[ "${PIPESTATUS[0]}" -eq 0 ] || FAIL=1

echo "== 5. Tes asap (semua profil render x tile x beban, headless) =="
godot --headless --path game --script res://tests/smoke/run_smoke.gd 2>&1 | tee "$LOGS/smoke_tests.log"
[ "${PIPESTATUS[0]}" -eq 0 ] || FAIL=1
if grep -E "SCRIPT ERROR|Parse Error" "$LOGS/smoke_tests.log"; then FAIL=1; fi

if [ "$FAIL" -ne 0 ]; then echo "VALIDASI GAGAL"; exit 1; fi
echo "VALIDASI LOLOS"
