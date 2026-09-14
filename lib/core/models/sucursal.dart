/// Espejo de `SucursalOpcion` (`app/modules/sucursales/schemas.py`).
class SucursalOpcion {
  final int id;
  final String nombre;
  final String ciudad;

  SucursalOpcion({required this.id, required this.nombre, required this.ciudad});

  factory SucursalOpcion.fromJson(Map<String, dynamic> json) => SucursalOpcion(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    ciudad: json['ciudad'] as String,
  );
}
