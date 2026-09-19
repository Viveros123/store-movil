import 'package:flutter/material.dart';

import '../../core/models/catalogo.dart';
import '../../core/widgets/precio_promo.dart';

/// Tarjeta de producto para la grilla del catálogo (CU9).
class ProductoCard extends StatelessWidget {
  final CatalogoProducto producto;
  final VoidCallback onTap;

  const ProductoCard({super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded (no AspectRatio fijo): así la imagen cede espacio al
          // texto en vez de desbordar la tarjeta cuando el nombre ocupa
          // 2 líneas o la letra del sistema es más grande.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: producto.imagenUrl == null
                    ? const Icon(Icons.checkroom, size: 40)
                    : Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.checkroom, size: 40),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          PrecioPromo(
            precio: producto.precioBase,
            precioPromocional: producto.precioPromocional,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (producto.colores.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: producto.colores.take(4).map((c) {
                final color = _colorDesdeHex(c.codigoHex);
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
