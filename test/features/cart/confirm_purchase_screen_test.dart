import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/data/models/cart_item_model.dart';
import 'package:farmayopin/data/models/cart_model.dart';
import 'package:farmayopin/data/models/direccion_model.dart';
import 'package:farmayopin/data/models/tarjeta_model.dart';
import 'package:farmayopin/data/services/cart_service.dart';
import 'package:farmayopin/data/services/direccion_service.dart';
import 'package:farmayopin/data/services/tarjeta_service.dart';
import 'package:farmayopin/features/cart/presentation/screens/confirm_purchase_screen.dart';
import 'package:farmayopin/features/cart/presentation/screens/pago_exitoso_screen.dart';

class MockTarjetaService extends TarjetaService {
  final List<TarjetaModel> tarjetas;
  final bool shouldThrow;

  MockTarjetaService({
    this.tarjetas = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<TarjetaModel>> getTarjetas({String? token}) async {
    if (shouldThrow) {
      throw TarjetaException('Error al obtener tarjetas (500)');
    }
    return tarjetas;
  }
}

class MockDireccionService extends DireccionService {
  final List<DireccionModel> direcciones;
  final bool shouldThrow;

  MockDireccionService({
    this.direcciones = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<DireccionModel>> getDirecciones({String? token}) async {
    if (shouldThrow) {
      throw DireccionException('Error al obtener direcciones (500)');
    }
    return direcciones;
  }
}

class MockCartService extends CartService {
  bool pagarLlamado = false;
  final Map<String, dynamic> respuestaPago;

  MockCartService({this.respuestaPago = const {}});

  @override
  Future<Map<String, dynamic>> pagarCarrito({String? token}) async {
    pagarLlamado = true;
    return respuestaPago;
  }
}

void main() {
  const testCart = CartModel(
    id: 1,
    items: [
      CartItemModel(
        id: 101,
        productoId: 1,
        nombreProducto: 'Paracetamol 500 mg',
        foto: 'img/paracetamol.png',
        precioUnitario: 150.0,
        cantidad: 2,
        subtotal: 300.0,
      ),
    ],
    total: 300.0,
  );

  final testTarjetas = [
    const TarjetaModel(
      id: '10',
      tipo: 'CREDITO',
      marca: 'Visa',
      ultimosCuatro: '9999',
      titular: 'GASTON TEST',
      vencimiento: '12/28',
      isDefault: true,
    ),
    const TarjetaModel(
      id: '11',
      tipo: 'DEBITO',
      marca: 'Mastercard',
      ultimosCuatro: '1234',
      titular: 'GASTON TEST',
      vencimiento: '05/27',
      isDefault: false,
    ),
  ];

  final testDirecciones = [
    DireccionModel(
      id: '20',
      alias: 'Casa Principal',
      calle: 'Av. Gorlero',
      numero: '500',
      pisoDepto: 'Apto 101',
      ciudad: 'Punta del Este',
      isDefault: true,
    ),
    DireccionModel(
      id: '21',
      alias: 'Oficina Central',
      calle: 'Av. Roosevelt',
      numero: '800',
      pisoDepto: 'Of. 302',
      ciudad: 'Maldonado',
      isDefault: false,
    ),
  ];

  Widget createWidget({
    TarjetaService? tarjetaService,
    DireccionService? direccionService,
    CartService? cartService,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ConfirmPurchaseScreen(
        cart: testCart,
        token: 'test-token',
        tarjetaService: tarjetaService ??
            MockTarjetaService(tarjetas: testTarjetas),
        direccionService: direccionService ??
            MockDireccionService(direcciones: testDirecciones),
        cartService: cartService ?? MockCartService(),
      ),
    );
  }

  group('ConfirmPurchaseScreen Tests (100% API Driven)', () {
    testWidgets('Muestra datos reales de la API para tarjeta y dirección',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Resumen del pedido
      expect(find.text('Confirmar Compra'), findsOneWidget);
      expect(find.text('Resumen de tu pedido'), findsOneWidget);
      expect(find.text('Paracetamol 500 mg'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('\$300.00'), findsWidgets);

      // Tarjeta principal de la API
      expect(find.text('Visa Crédito'), findsOneWidget);
      expect(find.text('Terminada en 9999'), findsOneWidget);

      // Dirección principal de la API
      expect(find.text('Casa Principal'), findsOneWidget);
      expect(find.textContaining('Av. Gorlero 500'), findsOneWidget);

      // Botón confirmar pago
      expect(find.text('Confirmar pago'), findsOneWidget);
    });

    testWidgets('Cambiar tarjeta abre bottom sheet con tarjetas de la API y actualiza selección',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Visa Crédito'), findsOneWidget);

      // Tocar el primer "Cambiar" (tarjeta)
      final cambiarButtons = find.text('Cambiar');
      expect(cambiarButtons, findsNWidgets(2));
      await tester.tap(cambiarButtons.first);
      await tester.pumpAndSettle();

      // Verifica que abrió el modal con datos de la API únicamente
      expect(find.text('Seleccionar tarjeta de pago'), findsOneWidget);
      expect(find.text('Mastercard Débito'), findsOneWidget);
      expect(find.text('Gestionar o agregar tarjeta'), findsOneWidget);

      // Seleccionar Mastercard Débito
      await tester.tap(find.text('Mastercard Débito'));
      await tester.pumpAndSettle();

      // Modal cerrado y tarjeta actualizada en pantalla principal
      expect(find.text('Seleccionar tarjeta de pago'), findsNothing);
      expect(find.text('Mastercard Débito'), findsOneWidget);
      expect(find.text('Terminada en 1234'), findsOneWidget);
    });

    testWidgets('Cambiar dirección abre bottom sheet con direcciones de la API y actualiza selección',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Casa Principal'), findsOneWidget);

      // Tocar el segundo "Cambiar" (dirección de entrega)
      final cambiarButtons = find.text('Cambiar');
      await tester.tap(cambiarButtons.last);
      await tester.pumpAndSettle();

      // Verifica que abrió el modal con las direcciones de la API
      expect(find.text('Seleccionar dirección de entrega'), findsOneWidget);
      expect(find.text('Oficina Central'), findsOneWidget);
      expect(find.text('Gestionar o agregar dirección'), findsOneWidget);

      // Seleccionar Oficina Central
      await tester.tap(find.text('Oficina Central'));
      await tester.pumpAndSettle();

      // Modal cerrado y dirección actualizada
      expect(find.text('Seleccionar dirección de entrega'), findsNothing);
      expect(find.text('Oficina Central'), findsOneWidget);
      expect(find.textContaining('Av. Roosevelt 800'), findsOneWidget);
    });

    testWidgets('Muestra estado vacío cuando la API no tiene tarjetas ni direcciones',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(
        tarjetaService: MockTarjetaService(tarjetas: []),
        direccionService: MockDireccionService(direcciones: []),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No tienes tarjetas guardadas'), findsOneWidget);
      expect(find.textContaining('No tienes direcciones guardadas'), findsOneWidget);

      // Al tocar Confirmar pago sin tarjeta o sin dirección, muestra validación
      await tester.tap(find.text('Confirmar pago'));
      await tester.pump();

      expect(
        find.text('Debes agregar o seleccionar una tarjeta de pago para continuar'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra mensaje de error cuando la API falla',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(
        tarjetaService: MockTarjetaService(shouldThrow: true),
        direccionService: MockDireccionService(shouldThrow: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Error al obtener tarjetas (500)'), findsOneWidget);
      expect(find.text('Error al obtener direcciones (500)'), findsOneWidget);
      expect(find.text('Reintentar'), findsNWidgets(2));
    });

    testWidgets('Confirmar pago exitoso llama pagarCarrito y navega a PagoExitosoScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockCart = MockCartService(
        respuestaPago: {
          'id': 99,
          'fecha': DateTime.now().toIso8601String(),
          'total': 300.0,
          'clienteNombre': 'Gastón Test',
          'clienteEmail': 'gaston@example.com',
          'items': [
            {
              'id': 1,
              'productoId': 1,
              'nombreProducto': 'Paracetamol 500 mg',
              'cantidad': 2,
              'precioUnitario': 150.0,
              'subtotal': 300.0,
            }
          ],
        },
      );

      await tester.pumpWidget(createWidget(cartService: mockCart));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar pago'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockCart.pagarLlamado, isTrue);
      expect(find.byType(PagoExitosoScreen), findsOneWidget);
      expect(find.text('Compra realizada con éxito'), findsOneWidget);
      expect(find.text('#99'), findsOneWidget);
    });
  });
}
