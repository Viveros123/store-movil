import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/reserva.dart';
import '../../core/network/api_exception.dart';
import 'reserva_bolsa_service.dart';
import 'reservas_service.dart';

String _fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// CU16 — "Mi reserva": arma una reserva con varias prendas y elige el turno por sucursal.
class MiReservaPage extends StatelessWidget {
  final ReservasService reservas;

  const MiReservaPage({super.key, required this.reservas});

  void _alReservar(BuildContext context, Reserva reserva, String sucursal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva #${reserva.id} confirmada en $sucursal. La ves en "Mis reservas".',
        ),
      ),
    );
    if (context.read<ReservaBolsaService>().grupos.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = context.watch<ReservaBolsaService>().grupos;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi reserva')),
      body: SafeArea(
        child: grupos.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_outlined, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Todavía no agregaste prendas para probarte.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Elegí las prendas que querés probarte y reservá un turno. '
                    'Una reserva es de una sola sucursal: si agregaste prendas '
                    'de sucursales distintas, reservás cada grupo por separado.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final g in grupos) ...[
                    _GrupoReservaCard(
                      key: ValueKey(g.sucursalId),
                      grupo: g,
                      reservas: reservas,
                      onReservada: (r) => _alReservar(context, r, g.sucursal),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _GrupoReservaCard extends StatefulWidget {
  final GrupoBolsa grupo;
  final ReservasService reservas;
  final void Function(Reserva) onReservada;

  const _GrupoReservaCard({
    super.key,
    required this.grupo,
    required this.reservas,
    required this.onReservada,
  });

  @override
  State<_GrupoReservaCard> createState() => _GrupoReservaCardState();
}

class _GrupoReservaCardState extends State<_GrupoReservaCard> {
  DateTime _fecha = DateTime.now();
  int _duracionMinutos = 30;
  List<String> _slots = [];
  String? _horaSel;
  bool _cargandoSlots = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSlots();
  }

  Future<void> _cargarSlots() async {
    setState(() {
      _horaSel = null;
      _cargandoSlots = true;
    });
    try {
      final res = await widget.reservas.disponibilidad(
        sucursalId: widget.grupo.sucursalId,
        fechaIso: _fechaIso(_fecha),
        duracionMinutos: _duracionMinutos,
      );
      if (!mounted) return;
      setState(() {
        _slots = res.slots;
        _cargandoSlots = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _slots = [];
          _cargandoSlots = false;
        });
      }
    }
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
      _cargarSlots();
    }
  }

  Future<void> _confirmar() async {
    final hora = _horaSel;
    if (hora == null || _guardando) return;
    final bolsa = context.read<ReservaBolsaService>();
    final grupo = widget.grupo;

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final reserva = await widget.reservas.crear(
        sucursalId: grupo.sucursalId,
        fechaIso: _fechaIso(_fecha),
        horaInicio: hora.substring(0, 5),
        duracionMinutos: _duracionMinutos,
        items: grupo.items
            .map((i) => ItemReservaNueva(varianteId: i.varianteId, cantidad: i.cantidad))
            .toList(),
      );
      bolsa.quitarSucursal(grupo.sucursalId);
      widget.onReservada(reserva);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _guardando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo crear la reserva.';
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bolsa = context.read<ReservaBolsaService>();
    final grupo = widget.grupo;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.store_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${grupo.sucursal} — ${grupo.ciudad}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final item in grupo.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: item.imagenUrl == null
                            ? const Icon(Icons.checkroom, size: 20)
                            : Image.network(
                                item.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.checkroom, size: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productoNombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.talla ?? ''} · ${item.color ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: item.cantidad > 1
                          ? () => bolsa.cambiarCantidad(
                              item.varianteId,
                              item.sucursalId,
                              item.cantidad - 1,
                            )
                          : null,
                    ),
                    Text('${item.cantidad}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: item.cantidad < item.maxDisponible
                          ? () => bolsa.cambiarCantidad(
                              item.varianteId,
                              item.sucursalId,
                              item.cantidad + 1,
                            )
                          : null,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Quitar',
                      onPressed: () =>
                          bolsa.quitar(item.varianteId, item.sucursalId),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_fechaIso(_fecha)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 30, label: Text('30 min')),
                      ButtonSegment(value: 60, label: Text('1 hora')),
                    ],
                    selected: {_duracionMinutos},
                    onSelectionChanged: (s) {
                      setState(() => _duracionMinutos = s.first);
                      _cargarSlots();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Horario', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_cargandoSlots)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_slots.isEmpty)
              const Text('No hay turnos libres ese día. Probá otra fecha.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  return ChoiceChip(
                    label: Text(s.substring(0, 5)),
                    selected: _horaSel == s,
                    onSelected: (_) => setState(() => _horaSel = s),
                  );
                }).toList(),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (_horaSel == null || _guardando) ? null : _confirmar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar reserva en esta sucursal'),
            ),
          ],
        ),
      ),
    );
  }
}
