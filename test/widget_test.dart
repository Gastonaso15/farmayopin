import 'package:flutter/material.dart';
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

  testWidgets('Navegación de LoginScreen a RegisterScreen y retorno', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const FarmaYopinApp());
    await tester.pumpAndSettle();

    // Toca en "Regístrate"
    await tester.tap(find.textContaining('Regístrate'));
    await tester.pumpAndSettle();

    // Verifica que se encuentre en RegisterScreen
    expect(find.text('Crear cuenta'), findsNWidgets(2));
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    // Toca en volver a "Inicia sesión"
    await tester.tap(find.textContaining('Inicia sesión'));
    await tester.pumpAndSettle();

    // Verifica que volvió a LoginScreen
    expect(find.text('¡Hola de nuevo!'), findsOneWidget);
  });
}
