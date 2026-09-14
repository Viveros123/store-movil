import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../account/account_page.dart';
import '../catalogo/catalogo_page.dart';
import '../catalogo/tienda_service.dart';

/// Home autenticado: catálogo (CU9/CU10) como contenido principal,
/// cuenta y logout accesibles desde el AppBar.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FashionStore'),
        actions: [
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
      body: CatalogoPage(tienda: TiendaService(auth.api)),
    );
  }
}
