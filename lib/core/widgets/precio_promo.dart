import 'package:flutter/material.dart';

/// Color de las ofertas (CU33).
const colorOferta = Color(0xFFC2410C);

/// Precio con promoción (CU33): el precio original tachado y el precio con
/// descuento en color de oferta. Sin promoción muestra solo el precio normal.
class PrecioPromo extends StatelessWidget {
  final double precio;
  final double? precioPromocional;
  final TextStyle? style;

  const PrecioPromo({
    super.key,
    required this.precio,
    this.precioPromocional,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleSmall;
    final promo = precioPromocional;
    if (promo == null) {
      return Text('Bs ${precio.toStringAsFixed(2)}', style: base);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Bs ${precio.toStringAsFixed(2)}  ',
            style: base?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.lineThrough,
              fontSize: (base.fontSize ?? 14) * 0.85,
            ),
          ),
          TextSpan(
            text: 'Bs ${promo.toStringAsFixed(2)}',
            style: base?.copyWith(color: colorOferta),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta con el nombre de la promoción aplicada.
class EtiquetaOferta extends StatelessWidget {
  final String texto;

  const EtiquetaOferta(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: colorOferta,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
