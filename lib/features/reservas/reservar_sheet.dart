import 'package:flutter/material.dart';

import '../../core/models/catalogo.dart';
import '../../core/network/api_exception.dart';
import 'reservas_service.dart';

class ReservarSheetData {
  final int varianteId;
  final String productoNombre;
  final String? talla;
  final String? color;
  final List<DisponibilidadSucursal> sucursales;

  ReservarSheetData({
    required this.varianteId,
    required this.productoNombre,
    required this.talla,
    required this.color,
    required this.sucursales,
  });
}

String _fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// CU16 — formulario de reserva (sucursal, cantidad, fecha, duración, turno).
class ReservarSheet extends StatefulWidget {
  final ReservasService reservas;
  final ReservarSheetData data;

  const ReservarSheet({super.key, required this.reservas, required this.data});

  @override
  State<ReservarSheet> createState() => _ReservarSheetState();
}

class _ReservarSheetState extends State<ReservarSheet> {
  late int _sucursalId;
  int _cantidad = 1;
  DateTime _fecha = DateTime.now();
  int _duracionMinutos = 30;

  List<String> _slots = [];
  String? _horaSel;
  bool _cargandoSlots = false;
  bool _guardando = false;
  String? _error;

  DisponibilidadSucursal get _sucursalSel =>
      widget.data.sucursales.firstWhere((s) => s.sucursalId == _sucursalId);

  @override
  void initState() {
    super.initState();
    _sucursalId = widget.data.sucursales.first.sucursalId;
    _cargarSlots();
  }

  Future<void> _cargarSlots() async {
    setState(() {
      _horaSel = null;
      _cargandoSlots = true;
    });
    try {
      final res = await widget.reservas.disponibilidad(
        sucursalId: _sucursalId,
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
    if (hora == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final reserva = await widget.reservas.crear(
        sucursalId: _sucursalId,
        fechaIso: _fechaIso(_fecha),
        horaInicio: hora.substring(0, 5),
        duracionMinutos: _duracionMinutos,
        varianteId: widget.data.varianteId,
        cantidad: _cantidad,
      );
      if (mounted) Navigator.of(context).pop(reserva);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _guardando = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo crear la reserva.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxCantidad = _sucursalSel.cantidadDisponible;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // viewInsets = teclado; padding.bottom = barra de navegación del
        // celular (gestos o los 3 botones) — hay que sumar ambos.
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reservar para probar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              [
                widget.data.productoNombre,
                if (widget.data.talla != null || widget.data.color != null)
                  '${widget.data.talla ?? ''} · ${widget.data.color ?? ''}',
              ].join('  '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _sucursalId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sucursal',
                border: OutlineInputBorder(),
              ),
              items: widget.data.sucursales
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.sucursalId,
                      child: Text(
                        '${s.sucursal} — ${s.ciudad}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _sucursalId = v;
                  _cantidad = 1;
                });
                _cargarSlots();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Cantidad', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _cantidad > 1
                      ? () => setState(() => _cantidad--)
                      : null,
                ),
                Text('$_cantidad', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _cantidad < maxCantidad
                      ? () => setState(() => _cantidad++)
                      : null,
                ),
              ],
            ),
            Text(
              'Máximo $maxCantidad disponible(s) en esa sucursal.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            Text('Horario', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_cargandoSlots)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_slots.isEmpty)
              const Text('No hay turnos libres ese día. Probá otra fecha o sucursal.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  final sel = _horaSel == s;
                  return ChoiceChip(
                    label: Text(s.substring(0, 5)),
                    selected: sel,
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (_horaSel == null || _guardando) ? null : _confirmar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
