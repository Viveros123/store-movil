import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/sucursal.dart';
import '../../core/models/venta.dart';
import '../../core/network/api_exception.dart';
import '../carrito/carrito_service.dart';
import '../sucursales/sucursales_service.dart';
import 'mis_compras_page.dart';
import 'ventas_service.dart';

enum _Paso { sucursal, pago }

/// CU22/CU23 — Comprar desde la app (checkout + pago Stripe/QR).
class CheckoutPage extends StatefulWidget {
  final VentasService ventas;
  final SucursalesService sucursales;

  const CheckoutPage({
    super.key,
    required this.ventas,
    required this.sucursales,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  _Paso _paso = _Paso.sucursal;
  bool _cargando = true;
  bool _procesando = false;

  List<SucursalOpcion> _sucursalesOpciones = [];
  int? _sucursalId;
  Venta? _venta;
  Pago? _pago;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.sucursales
        .opciones()
        .then((res) {
          if (!mounted) return;
          setState(() {
            _sucursalesOpciones = res;
            _sucursalId = res.isNotEmpty ? res.first.id : null;
            _cargando = false;
          });
        })
        .catchError((_) {
          if (mounted) setState(() => _cargando = false);
        });
  }

  Future<void> _continuarAlPago() async {
    final sucursalId = _sucursalId;
    if (sucursalId == null || _procesando) return;

    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final venta = await widget.ventas.checkout(sucursalId);
      _venta = venta;
      if (mounted) {
        context.read<CarritoService>().cargar().catchError((_) {});
      }
      final pago = await widget.ventas.iniciarPago(venta.id);
      if (!mounted) return;
      setState(() {
        _pago = pago;
        _paso = _Paso.pago;
        _procesando = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _procesando = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo iniciar la compra.';
        _procesando = false;
      });
    }
  }

  Future<void> _irAPagar() async {
    final url = _pago?.checkoutUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _cancelarPedido() async {
    final venta = _venta;
    if (venta == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('¿Cancelar este pedido? El stock se libera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await widget.ventas.cancelar(venta.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido cancelado.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cancelar el pedido.')),
        );
      }
    }
  }

  void _verMisCompras() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MisComprasPage(ventas: widget.ventas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoService>().carrito;

    return Scaffold(
      appBar: AppBar(title: const Text('Comprar')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _paso == _Paso.sucursal
            ? _buildPasoSucursal(carrito?.total ?? 0)
            : _buildPasoPago(),
      ),
    );
  }

  Widget _buildPasoSucursal(double total) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Elegí la sucursal donde vas a retirar tu compra',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _sucursalId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sucursal de retiro',
              border: OutlineInputBorder(),
            ),
            items: _sucursalesOpciones
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${s.nombre} — ${s.ciudad}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _sucursalId = v),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Bs ${total.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_sucursalId == null || _procesando)
                ? null
                : _continuarAlPago,
            child: _procesando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar al pago'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoPago() {
    final pago = _pago!;
    Uint8List? qrBytes;
    if (pago.qrDataUrl != null) {
      final base64Str = pago.qrDataUrl!.split(',').last;
      try {
        qrBytes = base64Decode(base64Str);
      } catch (_) {
        qrBytes = null;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Pedido #${pago.ventaId} — Bs ${pago.monto.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (qrBytes != null)
            Center(
              child: Image.memory(qrBytes, width: 200, height: 200),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _irAPagar,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ir a pagar con Stripe'),
          ),
          const SizedBox(height: 12),
          Text(
            'Cuando termines de pagar, volvé a la app y entrá a "Mis compras" '
            'para confirmar el estado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _verMisCompras,
            child: const Text('Ver Mis compras'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelarPedido,
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
  }
}
