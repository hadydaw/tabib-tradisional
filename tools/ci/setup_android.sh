#!/usr/bin/env bash
# Siapkan Android SDK, debug keystore, dan pengaturan editor Godot untuk ekspor Android.
# Dijalankan di runner GitHub Ubuntu (Android SDK sudah terpasang di ANDROID_HOME).
set -euo pipefail

: "${GODOT_VERSION:?}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
JAVA_DIR="${JAVA_HOME:?JAVA_HOME tidak diatur (jalankan actions/setup-java dulu)}"
SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"

echo "Android SDK: $SDK"
echo "JAVA_HOME:   $JAVA_DIR"
java -version 2>&1 | head -1
[ -x "$SDKMANAGER" ] || { echo "sdkmanager tidak ditemukan di $SDKMANAGER" >&2; exit 1; }

yes | "$SDKMANAGER" --licenses >/dev/null || true
# Paket yang diminta dokumentasi ekspor Android Godot (bagian NDK/cmake hanya untuk build gradle).
"$SDKMANAGER" "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS:-35.0.1}" \
  "platforms;android-${ANDROID_PLATFORM:-35}" "cmdline-tools;latest" \
  | grep -vE '^\[=*' || true
"$SDKMANAGER" --list_installed | sed -n '1,40p'

# Debug keystore TETAP (tools/ci/debug.keystore, dikomit) supaya APK dari build berbeda
# bertanda tangan sama dan bisa saling meng-update. Kunci ini PUBLIK dan hanya untuk debug;
# kunci rilis nanti disimpan di GitHub Secrets, bukan di repo.
mkdir -p "$HOME/.android"
KS="$HOME/.android/debug.keystore"
cp "$(dirname "$0")/debug.keystore" "$KS"
keytool -list -keystore "$KS" -storepass android 2>/dev/null | grep -E "androiddebugkey|SHA" | head -2

# Pengaturan editor Godot (nama berkas berbeda antar versi minor, tulis keduanya)
SETTINGS_DIR="$HOME/.config/godot"
mkdir -p "$SETTINGS_DIR"
MINOR="$(echo "$GODOT_VERSION" | cut -d. -f1,2)"
for name in "editor_settings-4.tres" "editor_settings-${MINOR}.tres"; do
cat > "$SETTINGS_DIR/$name" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$SDK"
export/android/java_sdk_path = "$JAVA_DIR"
export/android/debug_keystore = "$KS"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF
done
echo "Pengaturan editor ditulis ke $SETTINGS_DIR"
