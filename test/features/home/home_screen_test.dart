import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/data/models/product_model.dart';
import 'package:farmayopin/data/services/catalog_service.dart';
import 'package:farmayopin/features/home/presentation/screens/home_screen.dart';

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
      ProductModel(
        id: 3,
        nombre: 'Shampoo Anticaspa 250ml',
        precio: 8.50,
        detalle: 'Cuidado capilar',
        foto: '',
        stock: 40,
        categoria: 'Cuidado Personal',
      ),
    ];
  }
}

void main() {
  Widget createTestWidget({String nombre = 'Gaston'}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: HomeScreen(
        nombre: nombre,
        email: 'gaston@example.com',
        token: 'mock-token',
        catalogService: MockCatalogService(),
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('Renderiza elementos principales: logo, saludo y categorías',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Saludo personalizado con el nombre del usuario
      expect(find.text('¡Hola, Gaston! 👋'), findsOneWidget);
      expect(find.text('¿Cómo podemos cuidar tu salud hoy?'), findsOneWidget);

      // Buscador rápido
      expect(
        find.text('Buscar medicamentos, vitaminas, etc...'),
        findsOneWidget,
      );

      // El carrusel de promociones y los beneficios ya no se muestran
      expect(find.text('20% OFF en Vitaminas'), findsNothing);
      expect(find.text('DESTACADO DE LA SEMANA'), findsNothing);
      expect(find.text('Envío Express'), findsNothing);

      // Categorías principales
      expect(find.text('Categorías Principales'), findsOneWidget);
      expect(find.text('Medicamentos'), findsWidgets);
      expect(find.text('Vitaminas'), findsWidgets);
      expect(find.text('Cuidado Personal'), findsWidgets);
      expect(find.text('Catálogo Completo'), findsOneWidget);

      // Productos Destacados
      expect(find.text('Productos Destacados'), findsOneWidget);
      expect(find.text('Vitamina C 1000mg'), findsWidgets);
      expect(find.text('Ibuprofeno 400mg'), findsOneWidget);

      // Barra de navegación inferior
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Catálogo'), findsOneWidget);
    });

    testWidgets('Tocar producto navega a la pantalla de detalle del cliente',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ibuprofeno 400mg'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del producto'), findsOneWidget);
      expect(find.text('Stock disponible: 150 unidades'), findsOneWidget);
    });

    testWidgets('Tocar en Categoría abre el catálogo con la categoría seleccionada',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar en la categoría "Cuidado Personal"
      await tester.tap(find.text('Cuidado Personal').first);
      await tester.pumpAndSettle();

      // Verifica que nos encontramos en la pantalla de Catálogo Completo
      expect(find.text('Catálogo Completo'), findsOneWidget);
      expect(find.text('Shampoo Anticaspa 250ml'), findsOneWidget);
      // El Ibuprofeno no debería aparecer porque la categoría filtrada es Cuidado Personal
      expect(find.text('Ibuprofeno 400mg'), findsNothing);
    });

    testWidgets('Tocar pestaña Catálogo en bottom nav navega a CatalogScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar en el ítem Catálogo del bottom nav
      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();

      // Debe abrir CatalogScreen con "Todos" por defecto
      expect(find.text('Catálogo Completo'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Vitamina C 1000mg'), findsOneWidget);
      expect(find.text('Ibuprofeno 400mg'), findsOneWidget);
    });
  });
}
