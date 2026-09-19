import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/features/profile/presentation/screens/profile_screen.dart';
import 'package:farmayopin/features/profile/presentation/screens/mis_datos_screen.dart';
import 'package:farmayopin/features/profile/presentation/screens/direccion_entrega_screen.dart';
import 'package:farmayopin/features/profile/presentation/screens/metodo_pago_screen.dart';

void main() {
  group('Profile Menu & New Screens Tests', () {
    testWidgets('Tocar "Mis datos" navega a MisDatosScreen y muestra datos',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(
            token: 'token-test',
            nombre: 'Gaston Perez',
            email: 'gaston@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis datos'), findsOneWidget);
      await tester.tap(find.text('Mis datos'));
      await tester.pumpAndSettle();

      // Verifica elementos de MisDatosScreen
      expect(find.text('Información Personal'), findsOneWidget);
      expect(find.text('Gaston Perez'), findsWidgets);
      expect(find.text('gaston@example.com'), findsWidgets);
      expect(find.text('Cédula de Identidad (CI)'), findsOneWidget);
      expect(find.text('4.567.890-1'), findsOneWidget);
      expect(find.text('+598 94 555 123'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('Tocar "Dirección de entrega" navega a DireccionEntregaScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(
            token: 'token-test',
            nombre: 'Gaston Perez',
            email: 'gaston@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dirección de entrega'));
      await tester.pumpAndSettle();

      // Verifica elementos de DireccionEntregaScreen localizados en Maldonado
      expect(find.text('Dirección de entrega'), findsWidgets);
      expect(find.text('Casa (Principal)'), findsOneWidget);
      expect(find.text('Maldonado (CP 20000)'), findsOneWidget);
      expect(find.text('Punta del Este, Maldonado (CP 20100)'), findsOneWidget);
      expect(find.text('San Carlos, Maldonado (CP 20400)'), findsOneWidget);
      expect(find.text('Predeterminada'), findsOneWidget);
      expect(find.text('Agregar nueva dirección'), findsOneWidget);
    });

    testWidgets('Tocar "Método de pago" navega a MetodoPagoScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(
            token: 'token-test',
            nombre: 'Gaston Perez',
            email: 'gaston@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Método de pago'));
      await tester.pumpAndSettle();

      // Verifica elementos de MetodoPagoScreen
      expect(find.text('FarmaYOpin Pay'), findsOneWidget);
      expect(find.text('Visa Crédito'), findsOneWidget);
      expect(find.text('Mercado Pago'), findsOneWidget);
      expect(find.text('Agregar tarjeta o método de pago'), findsOneWidget);
    });

    testWidgets('MisDatosScreen permite modificar y guardar datos',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MisDatosScreen(
            token: 'mock-token',
            nombre: 'Gaston Perez',
            email: 'gaston@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar en Guardar cambios
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Tus datos han sido actualizados con éxito.'), findsOneWidget);
    });

    testWidgets('DireccionEntregaScreen permite cambiar predeterminada y abrir modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DireccionEntregaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica direcciones iniciales
      expect(find.text('Casa (Principal)'), findsOneWidget);
      expect(find.text('Trabajo / Oficina'), findsOneWidget);

      // Tocar botón de agregar nueva dirección
      await tester.tap(find.text('Agregar nueva dirección'));
      await tester.pumpAndSettle();

      // El modal debe estar visible
      expect(find.text('Nueva Dirección de Entrega'), findsOneWidget);
      expect(find.text('Guardar dirección'), findsOneWidget);

      // Cerrar modal
      Navigator.of(tester.element(find.text('Nueva Dirección de Entrega'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Nueva Dirección de Entrega'), findsNothing);
    });

    testWidgets('MetodoPagoScreen permite interactuar con tarjetas y abrir modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MetodoPagoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica métodos iniciales
      expect(find.text('FarmaYOpin Pay'), findsOneWidget);
      expect(find.text('Visa Crédito'), findsOneWidget);
      expect(find.text('Mastercard Débito'), findsOneWidget);

      // Tocar botón de agregar tarjeta
      await tester.tap(find.text('Agregar tarjeta o método de pago'));
      await tester.pumpAndSettle();

      // Verifica campos del modal
      expect(find.text('Agregar Tarjeta de Crédito / Débito'), findsOneWidget);
      expect(find.text('Número de tarjeta'), findsOneWidget);
      expect(find.text('Guardar tarjeta'), findsOneWidget);
    });
  });
}
