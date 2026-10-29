#!/usr/bin/env bash
# Arma el instalador Linux de Ultimate Pixel con Tauri 2 (dentro de Docker).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
SRC=/opt/ultimate-pixel
(cd "$SRC" && npx vite build --outDir "$D/web" --emptyOutDir)
rm -f "$D/web/version.json"   # en la app no hay servidor que consultar
docker build -t ultimate-pixel-tauri-build "$D"
docker run --rm -e APPIMAGE_EXTRACT_AND_RUN=1 -e NO_STRIP=true \
  -v "$D":/app -v up-tauri-cargo:/usr/local/cargo/registry \
  ultimate-pixel-tauri-build \
  bash -c 'cd /app && tauri icon /app/src-tauri/icons/source.png -o /app/src-tauri/icons >/dev/null && tauri build --bundles deb,appimage'
