use tauri::AppHandle;
use tauri_plugin_opener::OpenerExt;

/// Abre fuera de la app un enlace del sitio o de una tienda (el APK nuevo, la ficha de la app).
/// Solo esos destinos: el juego no tiene por qué abrir otra cosa.
#[tauri::command]
fn open_url(app: AppHandle, url: String) -> Result<(), String> {
    const OK: [&str; 3] = ["https://iona.ar/", "https://play.google.com/", "https://apps.apple.com/"];
    if !OK.iter().any(|p| url.starts_with(p)) {
        return Err("enlace no permitido".into());
    }
    app.opener().open_url(url, None::<&str>).map_err(|e| e.to_string())
}

/// Baja la versión nueva, verifica la firma, la instala y reinicia. `false` si no había nada nuevo.
#[cfg(desktop)]
#[tauri::command]
async fn install_update(app: AppHandle) -> Result<bool, String> {
    use tauri_plugin_updater::UpdaterExt;
    let updater = app.updater().map_err(|e| e.to_string())?;
    let Some(update) = updater.check().await.map_err(|e| e.to_string())? else {
        return Ok(false);
    };
    update.download_and_install(|_, _| {}, || {}).await.map_err(|e| e.to_string())?;
    app.restart();
}

/// En Android la actualización la instala el sistema (ver `open_url`).
#[cfg(mobile)]
#[tauri::command]
async fn install_update() -> Result<bool, String> {
    Ok(false)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let builder = tauri::Builder::default().plugin(tauri_plugin_opener::init());
    #[cfg(desktop)]
    let builder = builder.plugin(tauri_plugin_updater::Builder::new().build());
    builder
        .invoke_handler(tauri::generate_handler![open_url, install_update])
        .run(tauri::generate_context!())
        .expect("error al iniciar Ultimate Pixel");
}
