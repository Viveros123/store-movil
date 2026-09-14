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

/// Home autenticado: catálogo (CU9/CU10) como contenido principal,
/// carrito, reservas, cuenta y logout accesibles desde el AppBar.
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cantidadCarrito = context.watch<CarritoService>().cantidadItems;
    final reservasService = ReservasService(auth.api);

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
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Mis reservas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MisReservasPage(reservas: reservasService),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi cuenta',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<CarritoService>().limpiarLocal();
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: CatalogoPage(
        tienda: TiendaService(auth.api),
        reservas: reservasService,
      ),
    );
  }
}
