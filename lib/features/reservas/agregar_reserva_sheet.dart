import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/catalogo.dart';
import 'reserva_bolsa_service.dart';

class AgregarReservaData {
  final int varianteId;
  final String productoNombre;
  final String? talla;
  final String? color;
  final String? imagenUrl;
  final List<DisponibilidadSucursal> sucursales;

  AgregarReservaData({
    required this.varianteId,
    required this.productoNombre,
    required this.talla,
    required this.color,
    required this.imagenUrl,
    required this.sucursales,
  });
}

/// CU16 — elegir en qué sucursal y cuántas unidades de esta prenda agregar a "Mi reserva".
class AgregarReservaSheet extends StatefulWidget {
  final AgregarReservaData data;

  const AgregarReservaSheet({super.key, required this.data});

  @override
  State<AgregarReservaSheet> createState() => _AgregarReservaSheetState();
}

class _AgregarReservaSheetState extends State<AgregarReservaSheet> {
  late int _sucursalId;
  int _cantidad = 1;

  DisponibilidadSucursal get _sucursalSel =>
      widget.data.sucursales.firstWhere((s) => s.sucursalId == _sucursalId);

  @override
  void initState() {
    super.initState();
    _sucursalId = widget.data.sucursales.first.sucursalId;
  }

  /// Lo disponible en la sucursal elegida, menos lo que ya está en "Mi reserva".
  int _maximo(ReservaBolsaService bolsa) {
    final resto =
        _sucursalSel.cantidadDisponible -
        bolsa.cantidadEnBolsa(widget.data.varianteId, _sucursalId);
    return resto < 0 ? 0 : resto;
  }

  void _agregar(ReservaBolsaService bolsa) {
    final s = _sucursalSel;
    bolsa.agregar(
      ItemBolsa(
        varianteId: widget.data.varianteId,
        productoNombre: widget.data.productoNombre,
        talla: widget.data.talla,
        color: widget.data.color,
        imagenUrl: widget.data.imagenUrl,
        sucursalId: s.sucursalId,
        sucursal: s.sucursal,
        ciudad: s.ciudad,
        cantidad: _cantidad,
        maxDisponible: s.cantidadDisponible,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bolsa = context.read<ReservaBolsaService>();
    final maximo = _maximo(bolsa);
    if (_cantidad > maximo && maximo > 0) _cantidad = maximo;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
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
              'Agregar a mi reserva',
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
            const SizedBox(height: 8),
            Text(
              'Una reserva es de una sola sucursal. Si elegís prendas de '
              'sucursales distintas, las reservás por separado.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
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
                  onPressed: _cantidad < maximo
                      ? () => setState(() => _cantidad++)
                      : null,
                ),
              ],
            ),
            Text(
              maximo > 0
                  ? 'Máximo $maximo más en esa sucursal.'
                  : 'Ya agregaste todo lo disponible en esa sucursal.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: maximo < 1 ? null : () => _agregar(bolsa),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
