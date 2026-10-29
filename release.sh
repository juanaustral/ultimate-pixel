#!/usr/bin/env bash
# Publica una versión de la app y avisa a los que la tienen instalada (NUEVA ACTUALIZACIÓN).
#   ./release.sh "notas de la versión"
# 1. APK firmado en el VPS (build-android.sh, que también arma web/ y fija la versión del juego).
# 2. Mac en GitHub Actions: commit y push de web/ y la versión, espera el run de ese commit y baja
#    el DMG y la .app comprimida.
# 3. Firma la .app para el actualizador con la clave de /opt/ultimate-pixel-secrets (no sale del VPS).
# 4. Copia todo a iona.ar/ultimatepixel/app/ y escribe app-latest.json (lo sirve api/app/latest).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
S=/opt/ultimate-pixel-secrets
PUB=/opt/iona-web/site/ultimatepixel/app
URL=https://iona.ar/ultimatepixel/app
LATEST=/opt/ultimate-pixel-data/app-latest.json
ENTREGA=/opt/iona-web/site/entregas/78c383a9f09573f4ee40ed0f   # link de prueba de Juan
NOTES=${1:-}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

bash "$D/build-android.sh"
V=$(cat "$D/web/app-version.txt")
APK="$D/dist-android/UltimatePixel-$V-arm64.apk"
[ -f "$APK" ] || { echo "no está $APK" >&2; exit 1; }

cd "$D"
git add web src-tauri/tauri.conf.json
git diff --cached --quiet || git commit -qm "Versión $V"
git push -q origin main
SHA=$(git rev-parse HEAD)
echo "esperando el build de Mac de $SHA..."
RUN=""
for _ in $(seq 1 360); do                       # hasta 3 horas (los runners de Mac a veces hacen cola)
  RUN=$(gh run list --commit "$SHA" --workflow macOS --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
  if [ -n "$RUN" ]; then
    ST=$(gh run view "$RUN" --json status,conclusion -q '.status + " " + .conclusion')
    case "$ST" in
      "completed success") break ;;
      "completed cancelled") echo "run $RUN cancelado: se relanza"; gh run rerun "$RUN" ;;
      completed*) echo "el build de Mac falló: $ST (run $RUN)" >&2; exit 1 ;;
    esac
  fi
  sleep 30
done
[ "$(gh run view "$RUN" --json conclusion -q .conclusion)" = success ] || { echo "el build de Mac no terminó" >&2; exit 1; }
gh run download "$RUN" -n ultimate-pixel-macos -D "$TMP"
DMG=$(find "$TMP" -name '*.dmg' | head -1)
TGZ=$(find "$TMP" -name 'UltimatePixel.app.tar.gz' | head -1)
[ -n "$DMG" ] && [ -n "$TGZ" ] || { echo "faltan el DMG o la .app en el run $RUN" >&2; exit 1; }

docker run --rm --env-file "$S/updater.env" -v "$S/updater.key":/k/updater.key:ro -v "$(dirname "$TGZ")":/w \
  ultimate-pixel-tauri-build tauri signer sign -f /k/updater.key /w/UltimatePixel.app.tar.gz >/dev/null
SIG=$(cat "$TGZ.sig")

mkdir -p "$PUB"
cp "$APK" "$PUB/UltimatePixel-$V-arm64.apk"
cp "$DMG" "$PUB/UltimatePixel-$V-mac.dmg"
cp "$TGZ" "$PUB/UltimatePixel-$V-mac.app.tar.gz"

python3 - "$LATEST" "$V" "$NOTES" "$URL" "$SIG" <<'EOF'
import json, os, sys, datetime
path, v, notes, url, sig = sys.argv[1:]
mac = {"signature": sig, "url": f"{url}/UltimatePixel-{v}-mac.app.tar.gz"}
data = {
    "version": v,
    "notes": notes,
    "pub_date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "platforms": {"darwin-aarch64": mac, "darwin-x86_64": mac},
    "android": {"url": f"{url}/UltimatePixel-{v}-arm64.apk"},
    "store": {"android": "", "ios": ""},
}
tmp = path + ".tmp"
with open(tmp, "w") as f: json.dump(data, f, indent=2)
os.chmod(tmp, 0o644); os.replace(tmp, path)
EOF

# página de prueba de Juan: siempre a la última
if [ -d "$ENTREGA" ]; then
  rm -f "$ENTREGA"/UltimatePixel-*
  cat > "$ENTREGA/index.html" <<EOF
<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>Ultimate Pixel apps</title>
<style>body{font:17px/1.5 system-ui,sans-serif;max-width:640px;margin:2em auto;padding:0 16px;background:#14301d;color:#f3f3f3}a{color:#ffc53d}li{margin:.6em 0}</style></head><body>
<h1>Ultimate Pixel $V</h1>
<ul>
<li><a href="$URL/UltimatePixel-$V-arm64.apk">Android: UltimatePixel-$V-arm64.apk</a></li>
<li><a href="$URL/UltimatePixel-$V-mac.dmg">Mac (Intel y Apple Silicon): UltimatePixel-$V-mac.dmg</a><br>No está firmada por Apple: la primera vez macOS la bloquea. Andá a Ajustes del Sistema &gt; Privacidad y seguridad y tocá "Abrir igual".</li>
</ul>
<p>Desde esta versión la app avisa sola cuando sale una nueva (NUEVA ACTUALIZACIÓN en el menú).</p>
</body></html>
EOF
fi

for f in "UltimatePixel-$V-arm64.apk" "UltimatePixel-$V-mac.dmg" "UltimatePixel-$V-mac.app.tar.gz"; do
  [ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/$f")" = 200 ] || { echo "no responde $URL/$f" >&2; exit 1; }
done
[ "$(curl -s https://iona.ar/ultimatepixel/api/app/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')" = "$V" ] \
  || { echo "api/app/latest no devuelve $V" >&2; exit 1; }
echo "PUBLICADA $V"
