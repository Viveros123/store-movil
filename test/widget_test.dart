import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_movil/main.dart';

void main() {
  // flutter_secure_storage no tiene implementación nativa en el entorno de
  // test (solo en el dispositivo/emulador real) — se simula el canal para
  // que AuthService.cargarSesion() no se quede esperando una respuesta.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  testWidgets('La app arranca y muestra la pantalla de login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FashionStoreApp());
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });
}
