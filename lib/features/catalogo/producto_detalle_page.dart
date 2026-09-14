import 'package:flutter/material.dart';

import '../../core/models/catalogo.dart';
import 'tienda_service.dart';

/// CU9 (detalle) + CU12 (disponibilidad por sucursal de la variante elegida).
/// "Reservar"/"Comprar" quedan deshabilitados hasta CU16/CU21 en Flutter.
class ProductoDetallePage extends StatefulWidget {
  final TiendaService tienda;
  final int productoId;

  const ProductoDetallePage({
    super.key,
    required this.tienda,
    required this.productoId,
  });

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  bool _cargando = true;
  bool _noEncontrado = false;
  CatalogoProductoDetalle? _producto;

  int? _colorSel;
  int? _tallaSel;

  List<DisponibilidadSucursal> _disponibilidad = [];
  bool _cargandoDisponibilidad = false;

  List<CatalogoVariante> get _variantes => _producto?.variantes ?? [];

  List<CatalogoVariante> get _coloresUnicos {
    final vistos = <int, CatalogoVariante>{};
    for (final v in _variantes) {
      vistos.putIfAbsent(v.colorId, () => v);
    }
    return vistos.values.toList();
  }

  List<CatalogoVariante> get _tallasParaColorSel {
    if (_colorSel == null) return _variantes;
    return _variantes.where((v) => v.colorId == _colorSel).toList();
  }

  CatalogoVariante? get _varianteSeleccionada {
    try {
      return _variantes.firstWhere(
        (v) => v.colorId == _colorSel && v.tallaId == _tallaSel,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final producto = await widget.tienda.detalle(widget.productoId);
      if (!mounted) return;
      setState(() {
        _producto = producto;
        _cargando = false;
        if (producto.variantes.isNotEmpty) {
          _colorSel = producto.variantes.first.colorId;
          _tallaSel = producto.variantes.first.tallaId;
        }
      });
      _cargarDisponibilidad();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _noEncontrado = true;
        });
      }
    }
  }

  Future<void> _cargarDisponibilidad() async {
    final variante = _varianteSeleccionada;
    if (variante == null) {
      setState(() => _disponibilidad = []);
      return;
    }
    setState(() => _cargandoDisponibilidad = true);
    try {
      final res = await widget.tienda.disponibilidad(variante.id);
      if (!mounted) return;
      setState(() {
        _disponibilidad = res;
        _cargandoDisponibilidad = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _disponibilidad = [];
          _cargandoDisponibilidad = false;
        });
      }
    }
  }

  void _elegirColor(int colorId) {
    setState(() {
      _colorSel = colorId;
      final disponibles = _tallasParaColorSel;
      if (!disponibles.any((v) => v.tallaId == _tallaSel)) {
        _tallaSel = disponibles.isNotEmpty ? disponibles.first.tallaId : null;
      }
    });
    _cargarDisponibilidad();
  }

  void _elegirTalla(int tallaId) {
    setState(() => _tallaSel = tallaId);
    _cargarDisponibilidad();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_noEncontrado || _producto == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Producto no encontrado.')),
      );
    }

    final producto = _producto!;
    final variante = _varianteSeleccionada;
    final imagen = variante?.imagenEfectivo ?? producto.imagenUrl;
    final precio = variante?.precioEfectivo ?? producto.precioBase;

    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      // SafeArea evita que la barra de navegación del celular tape los
      // botones de abajo (gestos o los 3 botones, según el dispositivo).
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: imagen == null
                      ? const Icon(Icons.checkroom, size: 64)
                      : Image.network(
                          imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.checkroom, size: 64),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (producto.categoria != null) ...[
              const SizedBox(height: 4),
              Text(
                producto.categoria!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Bs ${precio.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (producto.descripcion != null &&
                producto.descripcion!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(producto.descripcion!),
            ],
            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _coloresUnicos.map((v) {
                final sel = _colorSel == v.colorId;
                return GestureDetector(
                  onTap: () => _elegirColor(v.colorId),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _colorDesdeHex(v.colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: sel ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Talla', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tallasParaColorSel.map((v) {
                final sel = _tallaSel == v.tallaId;
                return ChoiceChip(
                  label: Text(v.talla ?? '-'),
                  selected: sel,
                  onSelected: (_) => _elegirTalla(v.tallaId),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Disponible en',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (_cargandoDisponibilidad)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_disponibilidad.isEmpty)
              const Text('Sin stock en ninguna sucursal por ahora.')
            else
              ..._disponibilidad.map(
                (d) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(d.sucursal),
                  subtitle: Text(d.ciudad),
                  trailing: Text('${d.cantidadDisponible} und.'),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Reservar (próximamente)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Agregar al carrito (próximamente)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _colorDesdeHex(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.grey;
  final limpio = hex.replaceAll('#', '');
  final valor = int.tryParse('FF$limpio', radix: 16);
  return valor == null ? Colors.grey : Color(valor);
}
