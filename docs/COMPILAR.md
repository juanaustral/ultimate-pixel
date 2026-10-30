# Compilar y publicar la app (Tauri 2)

Repositorio público `juanaustral/ultimate-pixel`: empaqueta el build web del juego, cuyo código está en el repositorio privado `juanaustral/ultimate-pixel-code` (en el VPS, `/opt/ultimate-pixel`).

- `build.sh`: compila el web (Vite) a `web/` y arma el instalador dentro de Docker (no instala nada en el VPS).
- Salida: `src-tauri/target/release/bundle/` (`deb/` y `appimage/`).

Limitación conocida: ranking, equipos guardados, cuentas y online usan `api/` relativo a la página;
en la app no hay servidor, así que solo anda el juego sin conexión.

## Otras plataformas
- Android (APK arm64, Pixel 3a): `build-android.sh` (Docker con SDK/NDK). Firma de prueba en `.keystore/` (fuera de git).
- macOS (DMG universal, firma ad-hoc, sin notarizar): GitHub Actions `.github/workflows/macos.yml` en el repo privado `juanaustral/ultimate-pixel-desktop`.
  `web/` va en git para que el runner no necesite el repo del juego. Regenerarlo con `build.sh` antes de cada push.

## Publicar una versión (`release.sh`)

`./release.sh "notas"` arma Linux (AppImage y .deb) y el APK firmado en el VPS, empuja `web/` y la versión, espera el DMG de GitHub Actions, firma la `.app` para el actualizador y publica todo en `https://iona.ar/ultimatepixel/app/`. Después escribe `/opt/ultimate-pixel-data/app-latest.json`, que la API sirve en `api/app/latest`: las apps instaladas muestran NUEVA ACTUALIZACIÓN en el menú. Windows se compila en Actions como Mac (`.github/workflows/windows.yml`, instalador NSIS por usuario). Al final crea el Release `vX.Y.Z` en este repositorio con nombres fijos (`UltimatePixel-Android.apk`, `-Windows.exe`, `-Mac.dmg`, `-Linux.AppImage`, `-Linux.deb`) para que los links del README den siempre la última.

- La versión de la app es siempre la del juego (`prepare-web.sh`; `check-version.sh` corta el build si no coinciden).
- Claves en `/opt/ultimate-pixel-secrets` (fuera de git, en el backup cifrado): `android-release.jks` firma el APK (no cambiarla nunca: Android no deja instalar encima una app firmada con otra) y `updater.key` firma las actualizaciones de Mac. Ninguna clave va a GitHub.
- Mac: el actualizador de Tauri baja, verifica la firma, instala y reinicia. Android: abre el APK nuevo y el sistema ofrece instalarlo (o la tienda, si `store.android` está cargado en `app-latest.json`).
- Android abre horizontal y en pantalla completa inmersiva (`android/MainActivity.kt`, copiada por `build-android.sh`).
