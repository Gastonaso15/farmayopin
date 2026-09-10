import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/theme/app_theme.dart';
import 'package:farmayopin/data/models/product_model.dart';
import 'package:farmayopin/features/catalog/presentation/screens/product_detail_admin_screen.dart';

void main() {
  const testProduct = ProductModel(
    id: 1,
    nombre: 'Vitamina C 1000mg',
    precio: 12.99,
    detalle:
        'Potente antioxidante que ayuda a fortalecer el sistema inmunologico.',
    foto: '',
    stock: 24,
    categoria: 'Suplementos Alimenticios',
  );

  const testProductSinStock = ProductModel(
    id: 2,
    nombre: 'Ibuprofeno 400mg',
    precio: 3.45,
    detalle: 'Analgésico y antipirético.',
    foto: '',
    stock: 0,
    categoria: 'Medicamentos',
  );

  Widget createTestWidget({
    required ProductModel product,
    VoidCallback? onEdit,
    VoidCallback? onViewHistory,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProductDetailAdminScreen(
        product: product,
        onEdit: onEdit,
        onViewPurchaseHistory: onViewHistory,
      ),
    );
  }

  group('ProductDetailAdminScreen Widget Tests', () {
    testWidgets(
      'Renderiza correctamente todos los datos del producto con stock',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(product: testProduct));
        await tester.pumpAndSettle();

        expect(find.text('Detalle del Producto'), findsOneWidget);
        expect(find.text('Vitamina C 1000mg'), findsOneWidget);
        expect(find.text('Suplementos Alimenticios'), findsOneWidget);
        expect(find.text('\$12.99'), findsOneWidget);
        expect(find.text('Stock disponible: 24 unidades'), findsOneWidget);
        expect(
          find.text(
            'Potente antioxidante que ayuda a fortalecer el sistema inmunologico.',
          ),
          findsOneWidget,
        );
        expect(find.text('Editar producto'), findsOneWidget);
        expect(find.text('Ver historial de compras'), findsOneWidget);
      },
    );

    testWidgets('Renderiza estado agotado si stock es 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(product: testProductSinStock));
      await tester.pumpAndSettle();

      expect(find.text('Producto sin stock disponible'), findsOneWidget);
    });

    testWidgets('Dispara callbacks al presionar botones de accion', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool editCalled = false;
      bool historyCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          product: testProduct,
          onEdit: () => editCalled = true,
          onViewHistory: () => historyCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar producto'));
      await tester.pump();
      expect(editCalled, isTrue);

      await tester.tap(find.text('Ver historial de compras'));
      await tester.pump();
      expect(historyCalled, isTrue);
    });
  });
}
