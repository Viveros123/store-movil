import '../../core/models/catalogo.dart';
import '../../core/network/api_client.dart';

/// CU9/CU10/CU12 — catálogo público, sin login (`/catalogo/...`).
class TiendaService {
  final ApiClient _api;

  TiendaService(this._api);

  String _conQuery(String path, Map<String, dynamic> params) {
    final limpio = <String, String>{};
    params.forEach((k, v) {
      if (v != null && v != '') limpio[k] = v.toString();
    });
    if (limpio.isEmpty) return path;
    return '$path?${Uri(queryParameters: limpio).query}';
  }

  Future<List<Categoria>> categorias() async {
    final data = await _api.get('/catalogo/categorias', auth: false) as List;
    return data.map((e) => Categoria.fromJson(e)).toList();
  }

  Future<List<Talla>> tallas() async {
    final data = await _api.get('/catalogo/tallas', auth: false) as List;
    return data.map((e) => Talla.fromJson(e)).toList();
  }

  Future<List<ColorCatalogo>> colores() async {
    final data = await _api.get('/catalogo/colores', auth: false) as List;
    return data.map((e) => ColorCatalogo.fromJson(e)).toList();
  }

  Future<List<CatalogoProducto>> destacados({int limit = 12}) async {
    final data =
        await _api.get(
              _conQuery('/catalogo/destacados', {'limit': limit}),
              auth: false,
            )
            as List;
    return data.map((e) => CatalogoProducto.fromJson(e)).toList();
  }

  Future<CatalogoPagina> listar({
    String? q,
    int? categoriaId,
    int? tallaId,
    int? colorId,
    double? precioMin,
    double? precioMax,
    String orden = 'novedad',
    int page = 1,
    int size = 24,
  }) async {
    final data = await _api.get(
      _conQuery('/catalogo/productos', {
        'q': q,
        'categoria_id': categoriaId,
        'talla_id': tallaId,
        'color_id': colorId,
        'precio_min': precioMin,
        'precio_max': precioMax,
        'orden': orden,
        'page': page,
        'size': size,
      }),
      auth: false,
    );
    return CatalogoPagina.fromJson(data as Map<String, dynamic>);
  }

  Future<CatalogoProductoDetalle> detalle(int id) async {
    final data = await _api.get('/catalogo/productos/$id', auth: false);
    return CatalogoProductoDetalle.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DisponibilidadSucursal>> disponibilidad(int varianteId) async {
    final data =
        await _api.get(
              '/catalogo/variantes/$varianteId/disponibilidad',
              auth: false,
            )
            as List;
    return data.map((e) => DisponibilidadSucursal.fromJson(e)).toList();
  }
}
