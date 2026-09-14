import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../account/account_page.dart';

/// Landing temporal tras iniciar sesión. Se irá ampliando con el catálogo (CU9+).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final usuario = auth.usuario!;

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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido, ${usuario.nombre}!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(usuario.email),
          ],
        ),
      ),
    );
  }
}
