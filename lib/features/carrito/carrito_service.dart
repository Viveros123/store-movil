import 'package:flutter/foundation.dart';

import '../../core/models/carrito.dart';
import '../../core/network/api_client.dart';

/// CU21 — Gestionar Carrito de Compras.
/// ChangeNotifier (como AuthService) para que el badge del contador en el
/// AppBar se actualice solo desde cualquier pantalla que agregue/quite ítems.
class CarritoService extends ChangeNotifier {
  final ApiClient _api;

  CarritoService(this._api);

  Carrito? _carrito;
  Carrito? get carrito => _carrito;
  int get cantidadItems => _carrito?.cantidadItems ?? 0;

  Future<void> cargar() async {
    final data = await _api.get('/carrito');
    _carrito = Carrito.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> agregar({required int varianteId, required int cantidad}) async {
    final data = await _api.post(
      '/carrito/items',
      body: {'variante_id': varianteId, 'cantidad': cantidad},
    );
    _carrito = Carrito.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> actualizarCantidad(int itemId, int cantidad) async {
    final data = await _api.patch(
      '/carrito/items/$itemId',
      body: {'cantidad': cantidad},
    );
    _carrito = Carrito.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> quitar(int itemId) async {
    final data = await _api.delete('/carrito/items/$itemId');
    _carrito = Carrito.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> vaciar() async {
    final data = await _api.delete('/carrito');
    _carrito = Carrito.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  void limpiarLocal() {
    _carrito = null;
    notifyListeners();
  }
}
