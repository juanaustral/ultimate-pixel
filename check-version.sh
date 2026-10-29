#!/usr/bin/env bash
# Falla si la versión de la app no es la del juego empaquetado en web/ (deben coincidir siempre).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
WEB=$(cat "$D/web/app-version.txt")
APP=$(node -p 'require(process.argv[1]).version' "$D/src-tauri/tauri.conf.json")
grep -qF "\"$WEB\"" "$D"/web/assets/*.js || { echo "web/ no trae la versión $WEB" >&2; exit 1; }
[ "$WEB" = "$APP" ] || { echo "versión distinta: juego $WEB, app $APP" >&2; exit 1; }
echo "versión $APP"
