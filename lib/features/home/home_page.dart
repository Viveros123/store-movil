import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../account/account_page.dart';
import '../carrito/carrito_page.dart';
import '../carrito/carrito_service.dart';
import '../catalogo/catalogo_page.dart';
import '../catalogo/tienda_service.dart';
import '../reservas/mis_reservas_page.dart';
import '../reservas/reservas_service.dart';
import '../ventas/mis_compras_page.dart';
import '../ventas/ventas_service.dart';

enum _MenuCuenta { cuenta, reservas, compras, salir }

/// Home autenticado: catálogo (CU9/CU10) como contenido principal,
/// carrito y menú de cuenta (reservas/compras/datos/logout) en el AppBar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Carga el carrito una vez al entrar, para que el badge del ícono
    // ya muestre la cantidad real sin esperar a abrir "Mi carrito".
    context.read<CarritoService>().cargar().catchError((_) {});
  }

  void _onMenu(_MenuCuenta opcion) {
    final auth = context.read<AuthService>();
    switch (opcion) {
      case _MenuCuenta.cuenta:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AccountPage()));
        break;
      case _MenuCuenta.reservas:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                MisReservasPage(reservas: ReservasService(auth.api)),
          ),
        );
        break;
      case _MenuCuenta.compras:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MisComprasPage(ventas: VentasService(auth.api)),
          ),
        );
        break;
      case _MenuCuenta.salir:
        context.read<CarritoService>().limpiarLocal();
        auth.logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cantidadCarrito = context.watch<CarritoService>().cantidadItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FashionStore'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$cantidadCarrito'),
              isLabelVisible: cantidadCarrito > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            tooltip: 'Mi carrito',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CarritoPage())),
          ),
          PopupMenuButton<_MenuCuenta>(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi cuenta',
            onSelected: _onMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuCuenta.cuenta,
                child: ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Mi cuenta'),
                ),
              ),
              PopupMenuItem(
                value: _MenuCuenta.reservas,
                child: ListTile(
                  leading: Icon(Icons.event_note_outlined),
                  title: Text('Mis reservas'),
                ),
              ),
              PopupMenuItem(
                value: _MenuCuenta.compras,
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Mis compras'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _MenuCuenta.salir,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: CatalogoPage(
        tienda: TiendaService(auth.api),
        reservas: ReservasService(auth.api),
      ),
    );
  }
}
