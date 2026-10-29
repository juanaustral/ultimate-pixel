# Ultimate Pixel — escritorio (prueba con Tauri 2, Linux)

Proyecto aparte: empaqueta el build web de `/opt/ultimate-pixel` sin modificar ese repo.

- `build.sh`: compila el web (Vite) a `web/` y arma el instalador dentro de Docker (no instala nada en el VPS).
- Salida: `src-tauri/target/release/bundle/` (`deb/` y `appimage/`).

Limitación conocida: ranking, equipos guardados, cuentas y online usan `api/` relativo a la página;
en la app no hay servidor, así que solo anda el juego sin conexión.

## Otras plataformas
- Android (APK arm64, Pixel 3a): `build-android.sh` (Docker con SDK/NDK). Firma de prueba en `.keystore/` (fuera de git).
- macOS (DMG universal, firma ad-hoc, sin notarizar): GitHub Actions `.github/workflows/macos.yml` en el repo privado `juanaustral/ultimate-pixel-desktop`.
  `web/` va en git para que el runner no necesite el repo del juego. Regenerarlo con `build.sh` antes de cada push.
