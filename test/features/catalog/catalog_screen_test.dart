import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/features/catalog/data/models/product_model.dart';
import 'package:farmayopin/features/catalog/data/services/catalog_service.dart';
import 'package:farmayopin/features/catalog/presentation/screens/catalog_screen.dart';

class MockCatalogService extends CatalogService {
  @override
  Future<List<ProductModel>> getProductos({String? token}) async {
    return const [
      ProductModel(
        id: 1,
        nombre: 'Vitamina C 1000mg',
        precio: 12.99,
        detalle: 'Suplemento antioxidante',
        foto: '',
        stock: 24,
        categoria: 'Vitaminas',
      ),
      ProductModel(
        id: 2,
        nombre: 'Ibuprofeno 400mg',
        precio: 3.45,
        detalle: 'Analgésico',
        foto: '',
        stock: 150,
        categoria: 'Medicamentos',
      ),
    ];
  }
}

void main() {
  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: CatalogScreen(catalogService: MockCatalogService()),
    );
  }

  group('CatalogScreen Widget Tests', () {
    testWidgets('Renderiza elementos principales: logo, búsqueda, chips y lista de productos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Catálogo Completo'), findsOneWidget);
      expect(find.text('Buscar productos, medicamentos...'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Medicamentos'), findsWidgets);
      expect(find.text('Vitaminas'), findsWidgets);

      // Verifica que los productos mock se muestren
      expect(find.text('Vitamina C 1000mg'), findsOneWidget);
      expect(find.text('Ibuprofeno 400mg'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);
      expect(find.text('\$3.45'), findsOneWidget);
    });

    testWidgets('Filtrado por categoría funciona correctamente', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Toca en el chip de "Vitaminas"
      await tester.tap(find.text('Vitaminas').first);
      await tester.pumpAndSettle();

      // Debe mostrar Vitamina C y no Ibuprofeno
      expect(find.text('Vitamina C 1000mg'), findsOneWidget);
      expect(find.text('Ibuprofeno 400mg'), findsNothing);
    });

    testWidgets('Búsqueda por texto filtra los productos en tiempo real', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Escribe en el campo de búsqueda
      await tester.enterText(find.byType(TextField), 'Ibu');
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofeno 400mg'), findsOneWidget);
      expect(find.text('Vitamina C 1000mg'), findsNothing);
    });
  });
}
