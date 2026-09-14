/// Modelos de reservas (CU16/CU17), espejo de
/// `app/modules/reservas/schemas.py`.
library;

class SlotsDisponibilidad {
  final bool cerrado;
  final List<String> slots; // "HH:MM:SS"

  SlotsDisponibilidad({required this.cerrado, required this.slots});

  factory SlotsDisponibilidad.fromJson(Map<String, dynamic> json) =>
      SlotsDisponibilidad(
        cerrado: json['cerrado'] as bool,
        slots: (json['slots'] as List<dynamic>).cast<String>(),
      );
}

class ItemReserva {
  final int varianteId;
  final String? producto;
  final String? talla;
  final String? color;
  final int cantidad;

  ItemReserva({
    required this.varianteId,
    required this.producto,
    required this.talla,
    required this.color,
    required this.cantidad,
  });

  factory ItemReserva.fromJson(Map<String, dynamic> json) => ItemReserva(
    varianteId: json['variante_id'] as int,
    producto: json['producto'] as String?,
    talla: json['talla'] as String?,
    color: json['color'] as String?,
    cantidad: json['cantidad'] as int,
  );
}

class Reserva {
  final int id;
  final int sucursalId;
  final String? sucursal;
  final String? ciudad;
  final String fecha; // "YYYY-MM-DD"
  final String horaInicio; // "HH:MM:SS"
  final String horaFin;
  final int duracionMinutos;
  final String estado;
  final List<ItemReserva> items;

  Reserva({
    required this.id,
    required this.sucursalId,
    required this.sucursal,
    required this.ciudad,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.duracionMinutos,
    required this.estado,
    required this.items,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as int,
    sucursalId: json['sucursal_id'] as int,
    sucursal: json['sucursal'] as String?,
    ciudad: json['ciudad'] as String?,
    fecha: json['fecha'] as String,
    horaInicio: json['hora_inicio'] as String,
    horaFin: json['hora_fin'] as String,
    duracionMinutos: json['duracion_minutos'] as int,
    estado: json['estado'] as String,
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => ItemReserva.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

const etiquetaEstadoReserva = {
  'PENDIENTE': 'Pendiente',
  'NOTIFICADA': 'Notificada',
  'PREPARADA': 'Preparada',
  'ATENDIDA': 'Atendida',
  'COMPLETADA': 'Completada',
  'CANCELADA': 'Cancelada',
  'EXPIRADA': 'Vencida',
};
