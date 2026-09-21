import 'package:flutter/material.dart';

import '../../core/models/catalogo.dart';

/// Prenda que se puede probar en el vestidor virtual (CU20).
///
/// Cada prenda es una imagen PNG con fondo transparente, dibujada de frente.
/// Para alinearla con el cuerpo se guardan dos "anclas": dónde están las
/// ARTICULACIONES de los hombros DENTRO de la imagen, como fracción del ancho
/// (dx) y del alto (dy) de la propia imagen, entre 0 y 1. ML Kit marca la
/// articulación, que queda más adentro y más abajo que la esquina de la
/// costura, por eso las anclas no están en la esquina de la prenda. La app
/// calcula escala, posición e inclinación para que esas anclas coincidan con
/// los hombros detectados en la foto.
///
/// La imagen viene de la app (`asset`) o del catálogo (`url`, campo
/// `imagen_ar_url` de la variante).
class PrendaAr {
  const PrendaAr({
    required this.nombre,
    required this.color,
    required this.hombroIzq,
    required this.hombroDer,
    this.asset,
    this.url,
    this.ancho,
    this.alto,
  });

  final String nombre;

  /// Color representativo, solo para el selector.
  final Color color;

  /// Imagen incluida en la app, o imagen del catálogo por URL.
  final String? asset;
  final String? url;

  /// Tamaño de la imagen en píxeles. Solo se conoce de antemano para las
  /// imágenes de la app; las de URL se miden al cargarlas.
  final double? ancho;
  final double? alto;

  /// Anclas de hombro como fracción (0 a 1) del ancho y del alto. "Izq" y
  /// "der" se refieren al lado izquierdo y derecho de la IMAGEN (no de la
  /// persona), igual que se ve en pantalla.
  final Offset hombroIzq;
  final Offset hombroDer;

  /// Identifica la imagen (sirve para cachear su tamaño).
  String get clave => asset ?? url ?? nombre;

  // Valores por defecto cuando la variante no trae anclas propias.
  static const _porDefectoIzq = Offset(0.27, 0.15);
  static const _porDefectoDer = Offset(0.73, 0.15);

  /// Arma la prenda a partir de una variante del catálogo con imagen AR.
  factory PrendaAr.desdeVariante(
    CatalogoVariante v, {
    required String nombreProducto,
  }) {
    final izq = (v.anclaIzqX != null && v.anclaIzqY != null)
        ? Offset(v.anclaIzqX!, v.anclaIzqY!)
        : _porDefectoIzq;
    final der = (v.anclaDerX != null && v.anclaDerY != null)
        ? Offset(v.anclaDerX!, v.anclaDerY!)
        : _porDefectoDer;
    return PrendaAr(
      nombre: v.color ?? nombreProducto,
      color: _colorDesdeHex(v.colorHex),
      url: v.imagenArUrl,
      hombroIzq: izq,
      hombroDer: der,
    );
  }
}

Color _colorDesdeHex(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.grey;
  final valor = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
  return valor == null ? Colors.grey : Color(valor);
}

/// Prendas de demostración incluidas en la app (polera y sudadera).
const prendasDemo = <PrendaAr>[
  PrendaAr(
    nombre: 'Polera verde',
    asset: 'assets/vestidor/polera_verde.png',
    color: Color(0xFF2F855A),
    ancho: 1000,
    alto: 960,
    hombroIzq: Offset(0.27, 0.15625),
    hombroDer: Offset(0.73, 0.15625),
  ),
  PrendaAr(
    nombre: 'Polera blanca',
    asset: 'assets/vestidor/polera_blanca.png',
    color: Color(0xFFF5F5F2),
    ancho: 1000,
    alto: 960,
    hombroIzq: Offset(0.27, 0.15625),
    hombroDer: Offset(0.73, 0.15625),
  ),
  PrendaAr(
    nombre: 'Sudadera negra',
    asset: 'assets/vestidor/sudadera_negra.png',
    color: Color(0xFF222226),
    ancho: 1000,
    alto: 1080,
    hombroIzq: Offset(0.27, 0.14352),
    hombroDer: Offset(0.73, 0.14352),
  ),
  PrendaAr(
    nombre: 'Sudadera vino',
    asset: 'assets/vestidor/sudadera_vino.png',
    color: Color(0xFF721C30),
    ancho: 1000,
    alto: 1080,
    hombroIzq: Offset(0.27, 0.14352),
    hombroDer: Offset(0.73, 0.14352),
  ),
];
