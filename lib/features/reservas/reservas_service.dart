import '../../core/models/reserva.dart';
import '../../core/network/api_client.dart';

/// CU16 (reservar) / CU17 (consultar y cancelar) — requiere sesión de Cliente.
class ReservasService {
  final ApiClient _api;

  ReservasService(this._api);

  Future<SlotsDisponibilidad> disponibilidad({
    required int sucursalId,
    required String fechaIso,
    required int duracionMinutos,
  }) async {
    final query = Uri(
      queryParameters: {
        'sucursal_id': '$sucursalId',
        'fecha': fechaIso,
        'duracion_minutos': '$duracionMinutos',
      },
    ).query;
    final data = await _api.get('/reservas/disponibilidad?$query');
    return SlotsDisponibilidad.fromJson(data as Map<String, dynamic>);
  }

  Future<Reserva> crear({
    required int sucursalId,
    required String fechaIso,
    required String horaInicio, // "HH:MM"
    required int duracionMinutos,
    required int varianteId,
    required int cantidad,
  }) async {
    final data = await _api.post(
      '/reservas',
      body: {
        'sucursal_id': sucursalId,
        'fecha': fechaIso,
        'hora_inicio': horaInicio,
        'duracion_minutos': duracionMinutos,
        'items': [
          {'variante_id': varianteId, 'cantidad': cantidad},
        ],
      },
    );
    return Reserva.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Reserva>> mias() async {
    final data = await _api.get('/reservas/mias') as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> cancelar(int reservaId) async {
    final data = await _api.post('/reservas/$reservaId/cancelar');
    return Reserva.fromJson(data as Map<String, dynamic>);
  }
}
