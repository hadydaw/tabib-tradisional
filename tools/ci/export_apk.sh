#!/usr/bin/env bash
# Ekspor APK debug Android dan periksa hasilnya (tanda tangan, manifest). Ini BUKAN uji di perangkat.
set -uo pipefail

LOGS="build/logs"; mkdir -p "$LOGS" build
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
APK="build/tabib-tradisional-debug.apk"
rm -f "$APK"

# Nomor versi naik otomatis tiap build agar Android menerimanya sebagai update.
if [ -n "${GITHUB_RUN_NUMBER:-}" ]; then
  sed -i "s/^version\/code=.*/version\/code=${GITHUB_RUN_NUMBER}/" game/export_presets.cfg
  echo "version/code = ${GITHUB_RUN_NUMBER}"
fi

godot --headless --path game --export-debug "Android Debug" "../$APK" 2>&1 | tee "$LOGS/export.log"

if [ ! -s "$APK" ]; then
  echo "GAGAL: APK tidak dihasilkan. Lihat $LOGS/export.log" >&2
  exit 1
fi

BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -n1)"
echo "== Inspeksi APK (build-tools: $BT) =="
{
  ls -l "$APK"
  sha256sum "$APK"
  "$BT/apksigner" verify --verbose --print-certs "$APK" 2>&1 | head -12
  "$BT/aapt2" dump badging "$APK" 2>&1 | grep -E "^(package|sdkVersion|minSdkVersion|targetSdkVersion|native-code|launchable-activity|application-label:)|screen-orientation|landscape" | head -20
  echo "-- Manifest: orientasi dan minSdk --"
  "$BT/aapt2" dump xmltree --file AndroidManifest.xml "$APK" 2>&1 | grep -iE "screenOrientation|minSdkVersion|targetSdkVersion|glEsVersion" | head -8
} 2>&1 | tee "$LOGS/apk_inspect.log"
