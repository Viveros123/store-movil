import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../network/api_client.dart';
import 'token_storage.dart';

/// Estado de sesión de la app: token + usuario actual.
/// CU1 (registro) y CU2 (login/logout) se apoyan en este mismo servicio.
class AuthService extends ChangeNotifier {
  final TokenStorage _tokenStorage = TokenStorage();
  late final ApiClient api = ApiClient(getToken: () => _token);

  String? _token;
  Usuario? _usuario;
  bool _cargando = true;

  Usuario? get usuario => _usuario;
  bool get estaAutenticado => _usuario != null;
  bool get cargando => _cargando;

  /// Se llama una vez al iniciar la app: intenta restaurar la sesión guardada.
  Future<void> cargarSesion() async {
    try {
      final token = await _tokenStorage.leer();
      if (token != null) {
        _token = token;
        final data = await api.get('/auth/me');
        _usuario = Usuario.fromJson(data as Map<String, dynamic>);
      }
    } catch (_) {
      // Sin almacenamiento seguro disponible, o token vencido/inválido:
      // se arranca sin sesión en vez de trabar la app.
      _token = null;
      _usuario = null;
      await _tokenStorage.borrar().catchError((_) {});
    }
    _cargando = false;
    notifyListeners();
  }

  /// CU1 — registro público de cliente. Devuelve al usuario ya autenticado.
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final data = await api.post(
      '/auth/registro',
      auth: false,
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      },
    ) as Map<String, dynamic>;

    _token = data['access_token'] as String;
    _usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
    await _tokenStorage.guardar(_token!);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _usuario = null;
    await _tokenStorage.borrar();
    notifyListeners();
  }
}
