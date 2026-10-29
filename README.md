# Ultimate Pixel — escritorio (prueba con Tauri 2, Linux)

Proyecto aparte: empaqueta el build web de `/opt/ultimate-pixel` sin modificar ese repo.

- `build.sh`: compila el web (Vite) a `web/` y arma el instalador dentro de Docker (no instala nada en el VPS).
- Salida: `src-tauri/target/release/bundle/` (`deb/` y `appimage/`).

Limitación conocida: ranking, equipos guardados, cuentas y online usan `api/` relativo a la página;
en la app no hay servidor, así que solo anda el juego sin conexión.
