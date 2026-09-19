import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/ia.dart';
import '../../core/widgets/precio_promo.dart';
import '../carrito/carrito_page.dart';
import '../carrito/carrito_service.dart';
import 'ia_service.dart';

class _MensajeMostrado {
  final MensajeChat mensaje;
  final List<ProductoMencionado> productos;

  _MensajeMostrado(this.mensaje, [this.productos = const []]);
}

/// CU30 — Consultar Asistente Virtual (Chatbot).
class AsistentePage extends StatefulWidget {
  final IaService ia;

  const AsistentePage({super.key, required this.ia});

  @override
  State<AsistentePage> createState() => _AsistentePageState();
}

class _AsistentePageState extends State<AsistentePage> {
  final _mensajeCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_MensajeMostrado> _mensajes = [
    _MensajeMostrado(
      MensajeChat(
        rol: 'asistente',
        texto:
            '¡Hola! Soy el asistente de FashionStore. Contame qué estás buscando y te ayudo a encontrarlo.',
      ),
    ),
  ];
  bool _enviando = false;

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;

    final historial = _mensajes.map((m) => m.mensaje).toList();

    setState(() {
      _mensajes.add(_MensajeMostrado(MensajeChat(rol: 'cliente', texto: texto)));
      _mensajeCtrl.clear();
      _enviando = true;
    });
    _irAlFinal();

    try {
      final res = await widget.ia.chat(texto, historial);
      if (!mounted) return;
      setState(() {
        _mensajes.add(
          _MensajeMostrado(
            MensajeChat(rol: 'asistente', texto: res.respuesta),
            res.productos,
          ),
        );
        _enviando = false;
      });
      // El chatbot puede agregar al carrito de verdad (CU30 + CU21):
      // refrescamos el badge y ofrecemos ir a verlo.
      if (res.carritoActualizado && mounted) {
        context.read<CarritoService>().cargar().catchError((_) {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El asistente agregó una prenda a tu carrito.'),
            action: SnackBarAction(
              label: 'Ver carrito',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CarritoPage()),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mensajes.add(
            _MensajeMostrado(
              MensajeChat(
                rol: 'asistente',
                texto: 'Tuve un problema para responder. Probá de nuevo en un momento.',
              ),
            ),
          );
          _enviando = false;
        });
      }
    }
    _irAlFinal();
  }

  void _irAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente virtual')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _mensajes.length + (_enviando ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _mensajes.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return _burbuja(context, _mensajes[i]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeCtrl,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        hintText: 'Escribí tu consulta...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _burbuja(BuildContext context, _MensajeMostrado m) {
    final esCliente = m.mensaje.rol == 'cliente';
    return Align(
      alignment: esCliente ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: esCliente
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.mensaje.texto,
              style: TextStyle(
                color: esCliente ? Colors.white : null,
              ),
            ),
            if (m.productos.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...m.productos.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: p.imagenUrl == null
                                ? const Icon(Icons.checkroom, size: 18)
                                : Image.network(p.imagenUrl!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              PrecioPromo(
                                precio: p.precioBase,
                                precioPromocional: p.precioPromocional,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
