import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Wrapper fino sobre `http` para hablar con el backend FastAPI:
/// arma la URL, serializa/deserializa JSON y traduce los errores
/// (`detail` de FastAPI, sea texto simple o lista de validación de Pydantic)
/// a un [ApiException] con un mensaje legible.
class ApiClient {
  final String? Function() getToken;

  ApiClient({required this.getToken});

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    final token = auth ? getToken() : null;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Para `/auth/login`, que espera `application/x-www-form-urlencoded`
  /// (OAuth2PasswordRequestForm de FastAPI), no JSON.
  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final res = await _wrap(() => http.post(_uri(path), body: fields));
    return _decode(res);
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await _wrap(
      () => http.get(_uri(path), headers: _headers(auth: auth)),
    );
    return _decode(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await _wrap(
      () => http.post(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await _wrap(
      () => http.patch(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await _wrap(
      () => http.delete(_uri(path), headers: _headers(auth: auth)),
    );
    return _decode(res);
  }

  Future<http.Response> _wrap(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw ApiException(
        'No se pudo conectar con el servidor. Revisá tu conexión.',
      );
    } on http.ClientException {
      throw ApiException(
        'No se pudo conectar con el servidor. Revisá tu conexión.',
      );
    }
  }

  dynamic _decode(http.Response res) {
    final bodyText = res.body.isEmpty ? null : utf8.decode(res.bodyBytes);
    final decoded = bodyText == null ? null : jsonDecode(bodyText);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw ApiException(_mensajeError(decoded), statusCode: res.statusCode);
  }

  String _mensajeError(dynamic decoded) {
    if (decoded is Map && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final primero = detail.first;
        if (primero is Map && primero['msg'] != null) {
          return primero['msg'].toString();
        }
      }
    }
    return 'Ocurrió un error inesperado. Intentá de nuevo.';
  }
}
