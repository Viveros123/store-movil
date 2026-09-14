/// Espejo de `UsuarioOut` del backend (`app/modules/identidad/schemas.py`).
class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final int rolId;
  final String? rol;
  final int? sucursalId;
  final int? proveedorId;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rolId,
    required this.rol,
    required this.sucursalId,
    required this.proveedorId,
    required this.activo,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    apellido: json['apellido'] as String,
    email: json['email'] as String,
    telefono: json['telefono'] as String?,
    rolId: json['rol_id'] as int,
    rol: json['rol'] as String?,
    sucursalId: json['sucursal_id'] as int?,
    proveedorId: json['proveedor_id'] as int?,
    activo: json['activo'] as bool,
  );
}
