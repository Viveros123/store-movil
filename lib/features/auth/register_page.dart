import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_exception.dart';
import 'login_page.dart';

/// CU1 — Registrar Cliente.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _enviando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    try {
      await context.read<AuthService>().registrar(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
      );
      // El AuthGate ya reconstruyó a HomePage por debajo, pero esta pantalla
      // se apiló con Navigator.push encima de Login: hay que sacarla para
      // que se vea.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FashionStore',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.length < 2) return 'Muy corto';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.length < 2) return 'Muy corto';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(val)) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_verPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmarCtrl,
                      obscureText: !_verPassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _enviando ? null : _registrar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _enviando
                          ? null
                          : () => Navigator.of(context).canPop()
                                ? Navigator.of(context).pop()
                                : Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  ),
                      child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
