import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/data/models/product_model.dart';
import 'package:farmayopin/data/models/producto_request.dart';
import 'package:farmayopin/data/services/catalog_service.dart';
import 'package:farmayopin/features/catalog/presentation/screens/create_product_screen.dart';

class MockCreateCatalogService extends CatalogService {
  @override
  Future<ProductModel> crearProducto(ProductoRequest request, {String? token}) async {
    return ProductModel(
      id: 99,
      nombre: request.nombre,
      precio: request.precio,
      detalle: request.detalle ?? '',
      foto: request.foto ?? '',
      stock: request.stock,
    );
  }
}

void main() {
  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: CreateProductScreen(catalogService: MockCreateCatalogService()),
    );
  }

  group('CreateProductScreen Widget Tests', () {
    testWidgets('Renderiza todos los campos y elementos del formulario', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Crear Producto'), findsNWidgets(2)); // Titulo y boton
      expect(find.text('Subir foto del producto'), findsOneWidget);
      expect(find.text('Nombre del producto'), findsOneWidget);
      expect(find.text('Descripción'), findsOneWidget);
      expect(find.text('Precio (\$)'), findsOneWidget);
      expect(find.text('Stock Inicial'), findsOneWidget);
    });

    testWidgets('Valida campos requeridos al enviar formulario vacio', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Presiona Crear Producto
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu nombre del producto'), findsOneWidget);
      expect(find.text('Por favor ingresa el precio'), findsOneWidget);
      expect(find.text('Por favor ingresa el stock'), findsOneWidget);
    });

    testWidgets('Permite ingresar valores validos y retornar el producto creado', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ProductModel? createdResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                createdResult = await Navigator.of(context).push<ProductModel>(
                  MaterialPageRoute(
                    builder: (_) => CreateProductScreen(catalogService: MockCreateCatalogService()),
                  ),
                );
              },
              child: const Text('Abrir Crear'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Crear'));
      await tester.pumpAndSettle();

      // Rellenar campos
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Amoxicilina 500mg');
      await tester.enterText(textFields.at(1), 'Antibiotico de amplio espectro');
      await tester.enterText(textFields.at(2), '14.50');
      await tester.enterText(textFields.at(3), '50');
      await tester.pumpAndSettle();

      // Presiona Crear Producto
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Producto'));
      await tester.pumpAndSettle();

      expect(createdResult, isNotNull);
      expect(createdResult!.nombre, 'Amoxicilina 500mg');
      expect(createdResult!.precio, 14.50);
      expect(createdResult!.stock, 50);
    });
  });
}
