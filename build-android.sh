#!/usr/bin/env bash
# Arma el APK de Ultimate Pixel (arm64, p. ej. Pixel 3a) con Tauri 2, dentro de Docker.
# Requiere la imagen base de build.sh. Firma con la clave definitiva de /opt/ultimate-pixel-secrets
# (android-release.jks y .env, fuera de git y en el backup cifrado): sin ella no hay actualizaciones.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
S=/opt/ultimate-pixel-secrets
[ -f $S/android-release.jks ] || { echo "falta la clave de firma en $S" >&2; exit 1; }
bash "$D/prepare-web.sh"
VERSION=$(cat "$D/web/app-version.txt")
docker build -t ultimate-pixel-tauri-android -f "$D/Dockerfile.android" "$D"
docker run --rm --env-file $S/android-release.env -e VERSION="$VERSION" -v "$D":/app -v $S/android-release.jks:/key/release.jks:ro -v up-tauri-cargo:/usr/local/cargo/registry -v up-gradle:/root/.gradle \
  ultimate-pixel-tauri-android bash -c '
  set -e; cd /app
  npm install --no-audit --no-fund >/dev/null
  [ -d src-tauri/gen/android ] || npm run tauri -- android init --ci
  # init deja el ícono de Tauri: se pisan con los del juego (tauri icon los genera en icons/android)
  cp -r src-tauri/icons/android/. src-tauri/gen/android/app/src/main/res/
  sed -i "s/#FFFFFF/#4FA457/" src-tauri/gen/android/app/src/main/res/values/ic_launcher_background.xml   # verde de la cancha
  npm run tauri -- android build --apk --target aarch64 --ci
  IN=$(find src-tauri/gen/android -name "*release-unsigned.apk" | head -1)
  mkdir -p dist-android
  zipalign -f 4 "$IN" /tmp/aligned.apk
  OUT=dist-android/UltimatePixel-$VERSION-arm64.apk
  apksigner sign --ks /key/release.jks --ks-key-alias "$ANDROID_KEY_ALIAS" --ks-pass env:ANDROID_KEY_PASSWORD --key-pass env:ANDROID_KEY_PASSWORD --out "$OUT" /tmp/aligned.apk
  apksigner verify "$OUT" && echo "APK_OK $OUT"'
