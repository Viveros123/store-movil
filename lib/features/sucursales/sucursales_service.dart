import '../../core/models/sucursal.dart';
import '../../core/network/api_client.dart';

class SucursalesService {
  final ApiClient _api;

  SucursalesService(this._api);

  Future<List<SucursalOpcion>> opciones() async {
    final data = await _api.get('/sucursales/opciones') as List;
    return data.map((e) => SucursalOpcion.fromJson(e)).toList();
  }
}
