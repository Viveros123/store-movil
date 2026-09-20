/// Modelos del catálogo público (CU9/CU10), espejo de
/// `app/modules/catalogo/schemas.py` y `app/modules/productos/schemas.py`.
library;

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class Categoria {
  final int id;
  final String nombre;

  Categoria({required this.id, required this.nombre});

  factory Categoria.fromJson(Map<String, dynamic> json) =>
      Categoria(id: json['id'] as int, nombre: json['nombre'] as String);
}

class Talla {
  final int id;
  final String valor;
  final String tipo;

  Talla({required this.id, required this.valor, required this.tipo});

  factory Talla.fromJson(Map<String, dynamic> json) => Talla(
    id: json['id'] as int,
    valor: json['valor'] as String,
    tipo: json['tipo'] as String,
  );
}

class ColorCatalogo {
  final int id;
  final String nombre;
  final String? codigoHex;

  ColorCatalogo({required this.id, required this.nombre, this.codigoHex});

  factory ColorCatalogo.fromJson(Map<String, dynamic> json) => ColorCatalogo(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    codigoHex: json['codigo_hex'] as String?,
  );
}

class CatalogoProducto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final String? coleccion;
  final String? temporada;
  final double precioBase;
  // CU33: precio con la mejor promoción vigente (null si no hay ninguna).
  final double? precioPromocional;
  final String? promocion;
  final String? imagenUrl;
  final List<ColorCatalogo> colores;
  final int cantidadVariantes;

  CatalogoProducto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.coleccion,
    required this.temporada,
    required this.precioBase,
    this.precioPromocional,
    this.promocion,
    required this.imagenUrl,
    required this.colores,
    required this.cantidadVariantes,
  });

  factory CatalogoProducto.fromJson(Map<String, dynamic> json) =>
      CatalogoProducto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        categoria: json['categoria'] as String?,
        coleccion: json['coleccion'] as String?,
        temporada: json['temporada'] as String?,
        precioBase: _toDouble(json['precio_base']) ?? 0,
        precioPromocional: _toDouble(json['precio_promocional']),
        promocion: json['promocion'] as String?,
        imagenUrl: json['imagen_url'] as String?,
        colores: (json['colores'] as List<dynamic>? ?? [])
            .map((e) => ColorCatalogo.fromJson(e as Map<String, dynamic>))
            .toList(),
        cantidadVariantes: json['cantidad_variantes'] as int? ?? 0,
      );
}

class CatalogoVariante {
  final int id;
  final int tallaId;
  final String? talla;
  final int colorId;
  final String? color;
  final String? colorHex;
  final double precioEfectivo;
  final double? precioPromocional;
  // Nombre de la promoción que aplica a esta variante puntual.
  final String? promocion;
  final String? imagenEfectivo;

  CatalogoVariante({
    required this.id,
    required this.tallaId,
    required this.talla,
    required this.colorId,
    required this.color,
    required this.colorHex,
    required this.precioEfectivo,
    this.precioPromocional,
    this.promocion,
    required this.imagenEfectivo,
  });

  factory CatalogoVariante.fromJson(Map<String, dynamic> json) =>
      CatalogoVariante(
        id: json['id'] as int,
        tallaId: json['talla_id'] as int,
        talla: json['talla'] as String?,
        colorId: json['color_id'] as int,
        color: json['color'] as String?,
        colorHex: json['color_hex'] as String?,
        precioEfectivo: _toDouble(json['precio_efectivo']) ?? 0,
        precioPromocional: _toDouble(json['precio_promocional']),
        promocion: json['promocion'] as String?,
        imagenEfectivo: json['imagen_efectivo'] as String?,
      );
}

class CatalogoProductoDetalle extends CatalogoProducto {
  final List<CatalogoVariante> variantes;

  CatalogoProductoDetalle({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.categoria,
    required super.coleccion,
    required super.temporada,
    required super.precioBase,
    super.precioPromocional,
    super.promocion,
    required super.imagenUrl,
    required super.colores,
    required super.cantidadVariantes,
    required this.variantes,
  });

  factory CatalogoProductoDetalle.fromJson(Map<String, dynamic> json) {
    final base = CatalogoProducto.fromJson(json);
    return CatalogoProductoDetalle(
      id: base.id,
      nombre: base.nombre,
      descripcion: base.descripcion,
      categoria: base.categoria,
      coleccion: base.coleccion,
      temporada: base.temporada,
      precioBase: base.precioBase,
      precioPromocional: base.precioPromocional,
      promocion: base.promocion,
      imagenUrl: base.imagenUrl,
      colores: base.colores,
      cantidadVariantes: base.cantidadVariantes,
      variantes: (json['variantes'] as List<dynamic>? ?? [])
          .map((e) => CatalogoVariante.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CatalogoPagina {
  final List<CatalogoProducto> items;
  final int total;
  final int page;
  final int size;

  CatalogoPagina({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  bool get hayMas => page * size < total;

  factory CatalogoPagina.fromJson(Map<String, dynamic> json) => CatalogoPagina(
    items: (json['items'] as List<dynamic>)
        .map((e) => CatalogoProducto.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int,
    page: json['page'] as int,
    size: json['size'] as int,
  );
}

/// CU12 — disponibilidad de una variante por sucursal.
class DisponibilidadSucursal {
  final int sucursalId;
  final String sucursal;
  final String ciudad;
  final int cantidadDisponible;

  DisponibilidadSucursal({
    required this.sucursalId,
    required this.sucursal,
    required this.ciudad,
    required this.cantidadDisponible,
  });

  factory DisponibilidadSucursal.fromJson(Map<String, dynamic> json) =>
      DisponibilidadSucursal(
        sucursalId: json['sucursal_id'] as int,
        sucursal: json['sucursal'] as String,
        ciudad: json['ciudad'] as String,
        cantidadDisponible: json['cantidad_disponible'] as int,
      );
}
