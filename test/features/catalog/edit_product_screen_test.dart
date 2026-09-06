import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/features/catalog/data/models/product_model.dart';
import 'package:farmayopin/features/catalog/data/models/producto_request.dart';
import 'package:farmayopin/features/catalog/data/services/catalog_service.dart';
import 'package:farmayopin/features/catalog/presentation/screens/edit_product_screen.dart';

class MockCatalogServiceForEdit extends CatalogService {
  ProductModel? lastUpdated;

  @override
  Future<ProductModel> actualizarProducto(int id, ProductoRequest request, {String? token}) async {
    final updated = ProductModel(
      id: id,
      nombre: request.nombre,
      precio: request.precio,
      detalle: request.detalle ?? '',
      foto: request.foto ?? '',
      stock: request.stock,
      categoria: 'Medicamentos',
    );
    lastUpdated = updated;
    return updated;
  }
}

void main() {
  const initialProduct = ProductModel(
    id: 10,
    nombre: 'Vitamina C 1000mg',
    precio: 12.99,
    detalle: 'Potente antioxidante que ayuda a fortalecer el sistema inmunologico.',
    foto: '',
    stock: 24,
    categoria: 'Vitaminas',
  );

  Widget createTestWidget({
    required ProductModel product,
    CatalogService? catalogService,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: EditProductScreen(
        product: product,
        catalogService: catalogService,
      ),
    );
  }

  group('EditProductScreen Widget Tests', () {
    testWidgets('Precarga correctamente los datos del producto existente en los campos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(product: initialProduct));
      await tester.pumpAndSettle();

      expect(find.text('Editar Producto'), findsOneWidget);
      expect(find.text('Vitamina C 1000mg'), findsWidgets);
      expect(find.text('Potente antioxidante que ayuda a fortalecer el sistema inmunologico.'), findsWidgets);
      expect(find.text('12.99'), findsWidgets);
      expect(find.text('24'), findsWidgets);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('Valida campos requeridos al vaciar el nombre', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(product: initialProduct));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), ''); // Nombre
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu nombre del producto'), findsOneWidget);
    });

    testWidgets('Permite modificar valores y llama a actualizarProducto', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockCatalogServiceForEdit();

      await tester.pumpWidget(
        createTestWidget(
          product: initialProduct,
          catalogService: mockService,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Vitamina C Plus 1000mg');
      await tester.enterText(textFields.at(2), '15.50');
      await tester.enterText(textFields.at(3), '35');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(mockService.lastUpdated, isNotNull);
      expect(mockService.lastUpdated!.id, 10);
      expect(mockService.lastUpdated!.nombre, 'Vitamina C Plus 1000mg');
      expect(mockService.lastUpdated!.precio, 15.50);
      expect(mockService.lastUpdated!.stock, 35);
    });
  });
}
