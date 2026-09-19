import '../../core/models/venta.dart';
import '../../core/network/api_client.dart';

/// CU22/CU23 (comprar) + CU27 (pago Stripe/QR) + CU28 (confirmar pago).
class VentasService {
  final ApiClient _api;

  VentasService(this._api);

  Future<Venta> checkout(String direccion, String? referencia) async {
    final data = await _api.post(
      '/ventas/checkout',
      body: {'direccion_entrega': direccion, 'referencia_entrega': referencia},
    );
    return Venta.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Venta>> misCompras() async {
    final data = await _api.get('/ventas/mias') as List;
    return data.map((e) => Venta.fromJson(e)).toList();
  }

  Future<Venta> cancelar(int ventaId) async {
    final data = await _api.post('/ventas/$ventaId/cancelar');
    return Venta.fromJson(data as Map<String, dynamic>);
  }

  Future<Pago> iniciarPago(int ventaId) async {
    final data = await _api.post('/ventas/$ventaId/pagos');
    return Pago.fromJson(data as Map<String, dynamic>);
  }

  Future<EstadoPagoInfo> estadoPago(int ventaId) async {
    final data = await _api.get('/ventas/$ventaId/pagos/estado');
    return EstadoPagoInfo.fromJson(data as Map<String, dynamic>);
  }
}
