#!/usr/bin/env bash
# Pasang Godot (headless/editor linux) dan export template Android dari rilis resmi.
# Env: GODOT_VERSION (mis. 4.7.2), GODOT_RELEASE (mis. stable)
set -euo pipefail

: "${GODOT_VERSION:?}"; : "${GODOT_RELEASE:=stable}"
TAG="${GODOT_VERSION}-${GODOT_RELEASE}"
DL="${HOME}/godot-dl"
mkdir -p "$DL"

fetch() { # $1 = nama berkas
  local f="$DL/$1"
  if [ -s "$f" ]; then echo "cache: $1"; return 0; fi
  for base in \
    "https://github.com/godotengine/godot/releases/download/${TAG}" \
    "https://github.com/godotengine/godot-builds/releases/download/${TAG}"; do
    echo "unduh: ${base}/$1"
    if curl -fL --retry 3 --retry-delay 5 -o "$f.part" "${base}/$1"; then
      mv "$f.part" "$f"; return 0
    fi
  done
  echo "GAGAL mengunduh $1 untuk ${TAG}" >&2
  return 1
}

BIN_ZIP="Godot_v${TAG}_linux.x86_64.zip"
TPZ="Godot_v${TAG}_export_templates.tpz"
fetch "$BIN_ZIP"
fetch "$TPZ"

rm -rf "$DL/bin" && mkdir -p "$DL/bin"
unzip -q -o "$DL/$BIN_ZIP" -d "$DL/bin"
GODOT_BIN="$(find "$DL/bin" -maxdepth 1 -type f -name 'Godot_v*' | head -n1)"
sudo install -m 0755 "$GODOT_BIN" /usr/local/bin/godot

TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}"
rm -rf "$DL/tpl" && mkdir -p "$DL/tpl" "$TEMPLATE_DIR"
unzip -q -o "$DL/$TPZ" -d "$DL/tpl"
cp -r "$DL"/tpl/templates/* "$TEMPLATE_DIR"/

echo "Godot: $(godot --version)"
echo "Template: $TEMPLATE_DIR"
ls -la "$TEMPLATE_DIR" | grep -E 'android|version' || true
