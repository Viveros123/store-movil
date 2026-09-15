/// URL base del backend FastAPI.
///
/// Ya desplegado en Render (2026-09-14) — por defecto la app apunta ahí,
/// alcanzable desde cualquier celular sin cable ni `adb reverse`.
///
/// Para volver a pegarle al backend local durante desarrollo, override con:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   (emulador)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000  (USB + adb reverse tcp:8000 tcp:8000)
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://store-backend-i4g0.onrender.com',
  );
}
