/// URL base del backend FastAPI.
///
/// Mientras no esté desplegado, `localhost` no sirve desde un emulador/celular:
/// - Emulador Android: usar 10.0.2.2 (así el emulador ve el "localhost" de la PC).
/// - Celular físico (mismo WiFi que la PC): usar la IP de la PC en la red local,
///   ej. 192.168.0.x, y correr el backend con `--host 0.0.0.0`.
/// - iOS Simulator (Mac): localhost funciona directo.
///
/// Cuando el backend se despliegue (Render/Railway), este valor pasa a ser
/// la URL pública (https://...) y no hace falta tocar nada más del código.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
