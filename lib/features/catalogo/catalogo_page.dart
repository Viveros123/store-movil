import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/catalogo.dart';
import '../../core/models/ia.dart';
import '../ia/ia_service.dart';
import '../ia/recomendacion_card.dart';
import '../reservas/reservas_service.dart';
import 'producto_card.dart';
import 'producto_detalle_page.dart';
import 'tienda_service.dart';

const _opcionesOrden = {
  'novedad': 'Novedades',
  'precio_asc': 'Precio: menor a mayor',
  'precio_desc': 'Precio: mayor a menor',
  'nombre': 'Nombre (A-Z)',
};

/// CU9 (catálogo) + CU10 (búsqueda y filtros). Se embebe como body de
/// HomePage: el AppBar y la sesión los maneja la pantalla contenedora.
class CatalogoPage extends StatefulWidget {
  final TiendaService tienda;
  final ReservasService reservas;
  final IaService ia;

  const CatalogoPage({
    super.key,
    required this.tienda,
    required this.reservas,
    required this.ia,
  });

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  static const _size = 20;

  final _qCtrl = TextEditingController();
  final _precioMinCtrl = TextEditingController();
  final _precioMaxCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Timer? _debounce;

  List<Categoria> _categorias = [];
  List<Talla> _tallas = [];
  List<ColorCatalogo> _colores = [];

  int? _categoriaId;
  int? _tallaId;
  int? _colorId;
  String _orden = 'novedad';
  bool _panelAbierto = false;

  final List<CatalogoProducto> _productos = [];
  int _page = 1;
  int _total = 0;
  bool _cargando = true;
  bool _cargandoMas = false;

  List<ProductoRecomendado> _recomendaciones = [];
  bool _cargandoRecomendaciones = true;

  int get _filtrosActivos {
    var n = 0;
    if (_tallaId != null) n++;
    if (_colorId != null) n++;
    if (_precioMinCtrl.text.isNotEmpty) n++;
    if (_precioMaxCtrl.text.isNotEmpty) n++;
    return n;
  }

  @override
  void initState() {
    super.initState();
    widget.tienda.categorias().then((c) {
      if (mounted) setState(() => _categorias = c);
    });
    widget.tienda.tallas().then((t) {
      if (mounted) setState(() => _tallas = t);
    });
    widget.tienda.colores().then((c) {
      if (mounted) setState(() => _colores = c);
    });
    // CU29 — no bloquea el resto de la pantalla si falla.
    widget.ia
        .recomendaciones()
        .then((r) {
          if (mounted) {
            setState(() {
              _recomendaciones = r;
              _cargandoRecomendaciones = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _cargandoRecomendaciones = false);
        });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >
          _scrollCtrl.position.maxScrollExtent - 400) {
        _cargarMas();
      }
    });

    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onFiltroCambiado() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _cargar);
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _page = 1;
      _productos.clear();
    });
    try {
      final res = await widget.tienda.listar(
        q: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        categoriaId: _categoriaId,
        tallaId: _tallaId,
        colorId: _colorId,
        precioMin: double.tryParse(_precioMinCtrl.text),
        precioMax: double.tryParse(_precioMaxCtrl.text),
        orden: _orden,
        page: 1,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _productos.addAll(res.items);
        _total = res.total;
        _page = res.page;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMas() async {
    if (_cargandoMas || _cargando) return;
    if (_productos.length >= _total) return;

    setState(() => _cargandoMas = true);
    try {
      final res = await widget.tienda.listar(
        q: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        categoriaId: _categoriaId,
        tallaId: _tallaId,
        colorId: _colorId,
        precioMin: double.tryParse(_precioMinCtrl.text),
        precioMax: double.tryParse(_precioMaxCtrl.text),
        orden: _orden,
        page: _page + 1,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _productos.addAll(res.items);
        _page = res.page;
        _cargandoMas = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _limpiarFiltros() {
    _qCtrl.clear();
    _precioMinCtrl.clear();
    _precioMaxCtrl.clear();
    setState(() {
      _categoriaId = null;
      _tallaId = null;
      _colorId = null;
      _orden = 'novedad';
    });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(child: _buildBarraBusqueda(context)),
          if (_cargandoRecomendaciones || _recomendaciones.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecomendaciones(context)),
          if (_categorias.isNotEmpty)
            SliverToBoxAdapter(child: _buildChipsCategoria(context)),
          if (_panelAbierto) SliverToBoxAdapter(child: _buildPanelFiltros()),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: _buildGrilla(context),
          ),
          if (_cargandoMas)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecomendaciones(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Recomendado para vos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: _cargandoRecomendaciones
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recomendaciones.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final producto = _recomendaciones[i];
                      return RecomendacionCard(
                        producto: producto,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductoDetallePage(
                              tienda: widget.tienda,
                              reservas: widget.reservas,
                              productoId: producto.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar prendas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (_) => _onFiltroCambiado(),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            label: Text('$_filtrosActivos'),
            isLabelVisible: _filtrosActivos > 0,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.tune),
              tooltip: 'Filtros',
              onPressed: () => setState(() => _panelAbierto = !_panelAbierto),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onPressed: () => _mostrarOrden(context),
          ),
        ],
      ),
    );
  }

  void _mostrarOrden(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _opcionesOrden.entries
              .map(
                (e) => ListTile(
                  title: Text(e.value),
                  trailing: _orden == e.key
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() => _orden = e.key);
                    Navigator.pop(context);
                    _cargar();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChipsCategoria(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categorias[i];
          final seleccionado = _categoriaId == cat.id;
          return ChoiceChip(
            label: Text(cat.nombre),
            selected: seleccionado,
            onSelected: (_) {
              setState(() => _categoriaId = seleccionado ? null : cat.id);
              _cargar();
            },
          );
        },
      ),
    );
  }

  Widget _buildPanelFiltros() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Talla', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tallas.map((t) {
              final seleccionado = _tallaId == t.id;
              return ChoiceChip(
                label: Text(t.valor),
                selected: seleccionado,
                onSelected: (_) {
                  setState(() => _tallaId = seleccionado ? null : t.id);
                  _cargar();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colores.map((c) {
              final seleccionado = _colorId == c.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _colorId = seleccionado ? null : c.id);
                  _cargar();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _colorDesdeHexPublico(c.codigoHex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seleccionado
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: seleccionado ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Precio (Bs)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _precioMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mín',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _onFiltroCambiado(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _precioMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Máx',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _onFiltroCambiado(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _limpiarFiltros,
              child: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrilla(BuildContext context) {
    if (_cargando) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_productos.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No se encontraron prendas.')),
      );
    }
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      delegate: SliverChildBuilderDelegate((context, i) {
        final producto = _productos[i];
        return ProductoCard(
          producto: producto,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductoDetallePage(
                tienda: widget.tienda,
                reservas: widget.reservas,
                productoId: producto.id,
              ),
            ),
          ),
        );
      }, childCount: _productos.length),
    );
  }
}

Color _colorDesdeHexPublico(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.grey;
  final limpio = hex.replaceAll('#', '');
  final valor = int.tryParse('FF$limpio', radix: 16);
  return valor == null ? Colors.grey : Color(valor);
}
