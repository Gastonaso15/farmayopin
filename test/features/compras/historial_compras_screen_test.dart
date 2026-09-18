import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:farmayopin/data/models/compra_item_model.dart';
import 'package:farmayopin/data/models/compra_model.dart';
import 'package:farmayopin/data/services/cart_service.dart';
import 'package:farmayopin/data/services/compra_service.dart';
import 'package:farmayopin/features/compras/presentation/screens/historial_compras_screen.dart';

class MockCompraServiceOffline extends CompraService {
  final List<CompraModel> compras;
  final bool isOffline;

  MockCompraServiceOffline({
    required this.compras,
    required this.isOffline,
  });

  @override
  Future<CompraHistorialResult> getHistorialResult({
    String? token,
    String? userEmail,
  }) async {
    return CompraHistorialResult(
      compras: compras,
      isFromLocalDatabase: isOffline,
      noticeMessage: isOffline
          ? 'Modo sin conexión: mostrando historial guardado localmente en SQLite.'
          : null,
    );
  }
}

void main() {
  final testCompra = CompraModel(
    id: 123,
    fecha: DateTime(2026, 3, 10, 10, 0),
    total: 350.0,
    clienteNombre: 'Gastón',
    clienteEmail: 'gaston@example.com',
    items: const [
      CompraItemModel(
        id: 1,
        productoId: 10,
        nombreProducto: 'Ibuprofeno 400mg',
        cantidad: 1,
        precioUnitario: 350.0,
        subtotal: 350.0,
      ),
    ],
  );

  Widget createWidget(CompraService compraService) {
    return MaterialApp(
      home: HistorialComprasScreen(
        token: 'test-token',
        userEmail: 'gaston@example.com',
        compraService: compraService,
        cartService: CartService(
          client: MockClient((r) async => http.Response(
                '{"items":[],"cantidadUnidades":0,"subtotal":0.0,"descuentoTotal":0.0,"total":0.0}',
                200,
              )),
        ),
      ),
    );
  }

  group('HistorialComprasScreen Offline Widget Tests', () {
    testWidgets('Muestra banner de modo sin conexión cuando los datos vienen de SQLite local',
        (tester) async {
      final mockService = MockCompraServiceOffline(
        compras: [testCompra],
        isOffline: true,
      );

      await tester.pumpWidget(createWidget(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Historial de Compras'), findsOneWidget);
      expect(find.text('#123'), findsOneWidget);
      expect(find.text('\$350.00'), findsOneWidget);

      // Debe mostrar el banner offline
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(
        find.text(
          'Modo sin conexión: mostrando historial guardado localmente en SQLite.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('No muestra banner offline cuando los datos vienen del servidor online',
        (tester) async {
      final mockService = MockCompraServiceOffline(
        compras: [testCompra],
        isOffline: false,
      );

      await tester.pumpWidget(createWidget(mockService));
      await tester.pumpAndSettle();

      expect(find.text('#123'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    });
  });
}
