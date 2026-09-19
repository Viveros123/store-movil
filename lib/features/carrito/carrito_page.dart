import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/models/carrito.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/precio_promo.dart';
import '../ventas/checkout_page.dart';
import '../ventas/ventas_service.dart';
import 'carrito_service.dart';

/// CU21 — Gestionar Carrito de Compras.
class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  bool _cargando = true;
  int? _actualizando;

  @override
  void initState() {
    super.initState();
    context.read<CarritoService>().cargar().whenComplete(() {
      if (mounted) setState(() => _cargando = false);
    });
  }

  void _mostrarError(Object e) {
    final msg = e is ApiException
        ? e.message
        : 'No se pudo actualizar el carrito.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cambiarCantidad(ItemCarrito item, int delta) async {
    final nueva = item.cantidad + delta;
    if (nueva < 1 || nueva > 20) return;
    setState(() => _actualizando = item.id);
    try {
      await context.read<CarritoService>().actualizarCantidad(item.id, nueva);
    } catch (e) {
      if (mounted) _mostrarError(e);
    } finally {
      if (mounted) setState(() => _actualizando = null);
    }
  }

  Future<void> _quitar(ItemCarrito item) async {
    setState(() => _actualizando = item.id);
    try {
      await context.read<CarritoService>().quitar(item.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Se quitó del carrito.')));
      }
    } catch (e) {
      if (mounted) _mostrarError(e);
    } finally {
      if (mounted) setState(() => _actualizando = null);
    }
  }

  Future<void> _vaciar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Vaciar todo el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, vaciar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await context.read<CarritoService>().vaciar();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Carrito vacío.')));
      }
    } catch (e) {
      if (mounted) _mostrarError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoService>().carrito;
    final items = carrito?.items ?? [];
    final hayNoDisponibles = items.any((i) => !i.disponible);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Vaciar carrito',
              onPressed: _vaciar,
            ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const Center(child: Text('Tu carrito está vacío.'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _TarjetaItem(
                        item: items[i],
                        actualizando: _actualizando == items[i].id,
                        onSumar: () => _cambiarCantidad(items[i], 1),
                        onRestar: () => _cambiarCantidad(items[i], -1),
                        onQuitar: () => _quitar(items[i]),
                      ),
                    ),
                  ),
                  if (hayNoDisponibles)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Alguna prenda del carrito ya no tiene stock. Quitala para poder continuar.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Bs ${(carrito?.total ?? 0).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: hayNoDisponibles
                              ? null
                              : () {
                                  final api = context
                                      .read<AuthService>()
                                      .api;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CheckoutPage(ventas: VentasService(api)),
                                    ),
                                  );
                                },
                          child: const Text('Finalizar compra'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TarjetaItem extends StatelessWidget {
  final ItemCarrito item;
  final bool actualizando;
  final VoidCallback onSumar;
  final VoidCallback onRestar;
  final VoidCallback onQuitar;

  const _TarjetaItem({
    required this.item,
    required this.actualizando,
    required this.onSumar,
    required this.onRestar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: item.imagenEfectivo == null
                    ? Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.checkroom),
                      )
                    : Image.network(
                        item.imagenEfectivo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.checkroom),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${item.talla ?? ''} · ${item.color ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (!item.disponible)
                    const Text(
                      'Sin stock',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  if (item.promocion != null && item.precioOriginal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PrecioPromo(
                            precio: item.precioOriginal!,
                            precioPromocional: item.precioUnitario,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          EtiquetaOferta(item.promocion!),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: actualizando ? null : onRestar,
                      ),
                      Text('${item.cantidad}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: actualizando ? null : onSumar,
                      ),
                      const Spacer(),
                      Text(
                        'Bs ${(item.subtotal ?? 0).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Quitar',
              onPressed: actualizando ? null : onQuitar,
            ),
          ],
        ),
      ),
    );
  }
}
