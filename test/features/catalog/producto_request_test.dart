import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/data/models/producto_request.dart';

void main() {
  group('ProductoRequest Tests', () {
    test('toJson serializa correctamente los datos para el endpoint POST /api/productos', () {
      const request = ProductoRequest(
        nombre: 'Amoxicilina 500mg',
        precio: 14.50,
        detalle: 'Antibiotico de amplio espectro',
        foto: 'https://ejemplo.com/foto.jpg',
        stock: 50,
      );

      final json = request.toJson();

      expect(json['nombre'], 'Amoxicilina 500mg');
      expect(json['precio'], 14.50);
      expect(json['detalle'], 'Antibiotico de amplio espectro');
      expect(json['foto'], 'https://ejemplo.com/foto.jpg');
      expect(json['stock'], 50);
    });
  });
}
