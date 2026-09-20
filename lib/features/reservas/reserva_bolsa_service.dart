import 'package:flutter/foundation.dart';

/// Una prenda (variante) que el cliente quiere probarse, con la sucursal elegida.
class ItemBolsa {
  final int varianteId;
  final String productoNombre;
  final String? talla;
  final String? color;
  final String? imagenUrl;
  final int sucursalId;
  final String sucursal;
  final String ciudad;
  final int cantidad;
  final int maxDisponible;

  const ItemBolsa({
    required this.varianteId,
    required this.productoNombre,
    required this.talla,
    required this.color,
    required this.imagenUrl,
    required this.sucursalId,
    required this.sucursal,
    required this.ciudad,
    required this.cantidad,
    required this.maxDisponible,
  });

  ItemBolsa copyWith({int? cantidad, int? maxDisponible}) => ItemBolsa(
    varianteId: varianteId,
    productoNombre: productoNombre,
    talla: talla,
    color: color,
    imagenUrl: imagenUrl,
    sucursalId: sucursalId,
    sucursal: sucursal,
    ciudad: ciudad,
    cantidad: cantidad ?? this.cantidad,
    maxDisponible: maxDisponible ?? this.maxDisponible,
  );
}

/// Las prendas de una misma sucursal: cada grupo se reserva por separado.
class GrupoBolsa {
  final int sucursalId;
  final String sucursal;
  final String ciudad;
  final List<ItemBolsa> items;

  GrupoBolsa({
    required this.sucursalId,
    required this.sucursal,
    required this.ciudad,
    required this.items,
  });
}

/// "Mi reserva": prendas elegidas para reservar un turno de prueba. Vive en
/// la app (no hay tabla): recién al confirmar se crea la reserva real. Una
/// reserva es de una sola sucursal, por eso se agrupa por sucursal.
class ReservaBolsaService extends ChangeNotifier {
  final List<ItemBolsa> _items = [];

  List<ItemBolsa> get items => List.unmodifiable(_items);

  int get cantidad => _items.fold(0, (total, i) => total + i.cantidad);

  List<GrupoBolsa> get grupos {
    final porSucursal = <int, GrupoBolsa>{};
    for (final item in _items) {
      porSucursal
          .putIfAbsent(
            item.sucursalId,
            () => GrupoBolsa(
              sucursalId: item.sucursalId,
              sucursal: item.sucursal,
              ciudad: item.ciudad,
              items: [],
            ),
          )
          .items
          .add(item);
    }
    return porSucursal.values.toList();
  }

  int cantidadEnBolsa(int varianteId, int sucursalId) {
    for (final i in _items) {
      if (i.varianteId == varianteId && i.sucursalId == sucursalId) {
        return i.cantidad;
      }
    }
    return 0;
  }

  /// Si la prenda ya estaba en esa sucursal, suma la cantidad (sin pasar del stock).
  void agregar(ItemBolsa nuevo) {
    final pos = _items.indexWhere(
      (i) => i.varianteId == nuevo.varianteId && i.sucursalId == nuevo.sucursalId,
    );
    if (pos >= 0) {
      final suma = _items[pos].cantidad + nuevo.cantidad;
      _items[pos] = _items[pos].copyWith(
        cantidad: suma > nuevo.maxDisponible ? nuevo.maxDisponible : suma,
        maxDisponible: nuevo.maxDisponible,
      );
    } else {
      _items.add(nuevo);
    }
    notifyListeners();
  }

  void cambiarCantidad(int varianteId, int sucursalId, int cantidad) {
    final pos = _items.indexWhere(
      (i) => i.varianteId == varianteId && i.sucursalId == sucursalId,
    );
    if (pos < 0) return;
    final tope = _items[pos].maxDisponible;
    _items[pos] = _items[pos].copyWith(
      cantidad: cantidad < 1 ? 1 : (cantidad > tope ? tope : cantidad),
    );
    notifyListeners();
  }

  void quitar(int varianteId, int sucursalId) {
    _items.removeWhere(
      (i) => i.varianteId == varianteId && i.sucursalId == sucursalId,
    );
    notifyListeners();
  }

  void quitarSucursal(int sucursalId) {
    _items.removeWhere((i) => i.sucursalId == sucursalId);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}
