import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia segura del token de sesión (keystore/keychain nativo).
class TokenStorage {
  static const _key = 'access_token';
  final _storage = const FlutterSecureStorage();

  Future<void> guardar(String token) => _storage.write(key: _key, value: token);

  Future<String?> leer() => _storage.read(key: _key);

  Future<void> borrar() => _storage.delete(key: _key);
}
