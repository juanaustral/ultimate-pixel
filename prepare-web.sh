#!/usr/bin/env bash
# Compila el juego web a web/ y fija la versión de la app igual a la del juego (0.2.<commits de main>).
# Lo llaman build.sh y build-android.sh; el DMG de Mac usa el web/ y la versión que quedan versionados.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
SRC=${SRC:-/opt/ultimate-pixel}
[ "$(git -C "$SRC" rev-parse --abbrev-ref HEAD)" = main ] || { echo "el juego en $SRC no está en main" >&2; exit 1; }
VERSION="0.2.$(git -C "$SRC" rev-list --count HEAD)"
(cd "$SRC" && npx vite build --outDir "$D/web" --emptyOutDir)
rm -f "$D/web/version.json"   # en la app no hay servidor al lado que consultar
echo "$VERSION" > "$D/web/app-version.txt"
node -e '
  const fs = require("fs"), f = process.argv[1], c = JSON.parse(fs.readFileSync(f, "utf8"));
  c.version = process.argv[2]; fs.writeFileSync(f, JSON.stringify(c, null, 2) + "\n");' "$D/src-tauri/tauri.conf.json" "$VERSION"
bash "$D/check-version.sh"
