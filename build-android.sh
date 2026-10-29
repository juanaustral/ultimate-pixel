#!/usr/bin/env bash
# Arma el APK de Ultimate Pixel (arm64, p. ej. Pixel 3a) con Tauri 2, dentro de Docker.
# Requiere haber corrido build.sh antes (imagen base y web/).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
docker build -t ultimate-pixel-tauri-android -f "$D/Dockerfile.android" "$D"
docker run --rm -v "$D":/app -v up-tauri-cargo:/usr/local/cargo/registry -v up-gradle:/root/.gradle \
  ultimate-pixel-tauri-android bash -c '
  set -e; cd /app
  [ -d src-tauri/gen/android ] || tauri android init --ci
  tauri android build --apk --target aarch64 --ci
  [ -f /app/.keystore/test.jks ] || { mkdir -p /app/.keystore; keytool -genkeypair -keystore /app/.keystore/test.jks -alias up -keyalg RSA -keysize 2048 -validity 3650 -storepass prueba123 -keypass prueba123 -dname "CN=Ultimate Pixel prueba" >/dev/null; }
  IN=$(find src-tauri/gen/android -name "*release-unsigned.apk" | head -1)
  mkdir -p dist-android
  zipalign -f 4 "$IN" /tmp/aligned.apk
  apksigner sign --ks /app/.keystore/test.jks --ks-pass pass:prueba123 --out dist-android/UltimatePixel-0.2.0-arm64.apk /tmp/aligned.apk
  apksigner verify dist-android/UltimatePixel-0.2.0-arm64.apk && echo APK_OK'
