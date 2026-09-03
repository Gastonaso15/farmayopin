import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/main.dart';

void main() {
  testWidgets('LoginScreen smoke test: verifica elementos del formulario', (WidgetTester tester) async {
    await tester.pumpWidget(const FarmaYopinApp());
    await tester.pumpAndSettle();

    // Verifica que el logo y el texto de bienvenida estén presentes
    expect(find.text('¡Hola de nuevo!'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

    // Toca en Iniciar sesión sin completar los campos para verificar validaciones
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Por favor ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
  });
}
