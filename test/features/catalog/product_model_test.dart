import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/features/catalog/data/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    test('fromJson deserializa correctamente la respuesta de Spring Boot', () {
      final json = {
        'id': 10,
        'nombre': 'Ibuprofeno 600mg',
        'precio': 4.50,
        'detalle': 'Antiinflamatorio',
        'foto': 'https://example.com/foto.jpg',
        'stock': 40,
        'categoria': 'Medicamentos',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 10);
      expect(product.nombre, 'Ibuprofeno 600mg');
      expect(product.precio, 4.50);
      expect(product.detalle, 'Antiinflamatorio');
      expect(product.stock, 40);
      expect(product.categoria, 'Medicamentos');
    });

    test('toJson serializa correctamente los datos del producto', () {
      const product = ProductModel(
        id: 1,
        nombre: 'Paracetamol',
        precio: 2.0,
        detalle: 'Analgésico',
        foto: 'foto.png',
        stock: 10,
        categoria: 'Medicamentos',
      );

      final json = product.toJson();

      expect(json['id'], 1);
      expect(json['nombre'], 'Paracetamol');
      expect(json['precio'], 2.0);
    });
  });
}
