/// Modelos del carrito (CU21), espejo de `app/modules/ventas/schemas.py`.
library;

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class ItemCarrito {
  final int id;
  final int varianteId;
  final String? producto;
  final String? talla;
  final String? color;
  final String? imagenEfectivo;
  final double? precioUnitario;
  // CU33: precio sin descuento y nombre de la promoción aplicada, si hay.
  final double? precioOriginal;
  final String? promocion;
  final int cantidad;
  final double? subtotal;
  final bool disponible;

  ItemCarrito({
    required this.id,
    required this.varianteId,
    required this.producto,
    required this.talla,
    required this.color,
    required this.imagenEfectivo,
    required this.precioUnitario,
    this.precioOriginal,
    this.promocion,
    required this.cantidad,
    required this.subtotal,
    required this.disponible,
  });

  factory ItemCarrito.fromJson(Map<String, dynamic> json) => ItemCarrito(
    id: json['id'] as int,
    varianteId: json['variante_id'] as int,
    producto: json['producto'] as String?,
    talla: json['talla'] as String?,
    color: json['color'] as String?,
    imagenEfectivo: json['imagen_efectivo'] as String?,
    precioUnitario: _toDouble(json['precio_unitario']),
    precioOriginal: _toDouble(json['precio_original']),
    promocion: json['promocion'] as String?,
    cantidad: json['cantidad'] as int,
    subtotal: _toDouble(json['subtotal']),
    disponible: json['disponible'] as bool,
  );
}

class Carrito {
  final int id;
  final String estado;
  final List<ItemCarrito> items;
  final int cantidadItems;
  final double total;

  Carrito({
    required this.id,
    required this.estado,
    required this.items,
    required this.cantidadItems,
    required this.total,
  });

  factory Carrito.fromJson(Map<String, dynamic> json) => Carrito(
    id: json['id'] as int,
    estado: json['estado'] as String,
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => ItemCarrito.fromJson(e as Map<String, dynamic>))
        .toList(),
    cantidadItems: json['cantidad_items'] as int,
    total: _toDouble(json['total']) ?? 0,
  );
}
