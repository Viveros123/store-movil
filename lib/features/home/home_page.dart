import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../account/account_page.dart';
import '../catalogo/catalogo_page.dart';
import '../catalogo/tienda_service.dart';
import '../reservas/mis_reservas_page.dart';
import '../reservas/reservas_service.dart';

/// Home autenticado: catálogo (CU9/CU10) como contenido principal,
/// reservas, cuenta y logout accesibles desde el AppBar.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final reservasService = ReservasService(auth.api);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FashionStore'),
        actions: [
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
            onPressed: () => context.read<AuthService>().logout(),
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
