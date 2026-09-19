/// Modelos del módulo IA — CU29 (recomendador), CU30 (chatbot).
library;

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class ProductoRecomendado {
  final int id;
  final String nombre;
  final String? categoria;
  final String? temporada;
  final double precioBase;
  final double? precioPromocional;
  final String? imagenUrl;
  final String motivo;

  ProductoRecomendado({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.temporada,
    required this.precioBase,
    this.precioPromocional,
    required this.imagenUrl,
    required this.motivo,
  });

  factory ProductoRecomendado.fromJson(Map<String, dynamic> json) =>
      ProductoRecomendado(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        categoria: json['categoria'] as String?,
        temporada: json['temporada'] as String?,
        precioBase: _toDouble(json['precio_base']) ?? 0,
        precioPromocional: _toDouble(json['precio_promocional']),
        imagenUrl: json['imagen_url'] as String?,
        motivo: json['motivo'] as String,
      );
}

class MensajeChat {
  final String rol; // "cliente" | "asistente"
  final String texto;

  MensajeChat({required this.rol, required this.texto});

  Map<String, dynamic> toJson() => {'rol': rol, 'texto': texto};
}

class ProductoMencionado {
  final int id;
  final String nombre;
  final double precioBase;
  final double? precioPromocional;
  final String? imagenUrl;

  ProductoMencionado({
    required this.id,
    required this.nombre,
    required this.precioBase,
    this.precioPromocional,
    required this.imagenUrl,
  });

  factory ProductoMencionado.fromJson(Map<String, dynamic> json) =>
      ProductoMencionado(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        precioBase: _toDouble(json['precio_base']) ?? 0,
        precioPromocional: _toDouble(json['precio_promocional']),
        imagenUrl: json['imagen_url'] as String?,
      );
}

class ChatRespuesta {
  final String respuesta;
  final List<ProductoMencionado> productos;
  final bool carritoActualizado;

  ChatRespuesta({
    required this.respuesta,
    required this.productos,
    required this.carritoActualizado,
  });

  factory ChatRespuesta.fromJson(Map<String, dynamic> json) => ChatRespuesta(
    respuesta: json['respuesta'] as String,
    productos: (json['productos'] as List<dynamic>? ?? [])
        .map((e) => ProductoMencionado.fromJson(e as Map<String, dynamic>))
        .toList(),
    carritoActualizado: json['carrito_actualizado'] as bool? ?? false,
  );
}
