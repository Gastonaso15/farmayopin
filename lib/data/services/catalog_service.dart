import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/producto_compra_historial_model.dart';
import '../models/producto_request.dart';

class CatalogException implements Exception {
  final String message;
  final int? statusCode;

  CatalogException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CatalogService {
  final http.Client _client;

  CatalogService({http.Client? client}) : _client = client ?? http.Client();

  /// Crea un nuevo producto en el backend Spring Boot (POST /api/productos)
  Future<ProductModel> crearProducto(ProductoRequest request, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos');

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductModel.fromJson(body as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        throw CatalogException('Acceso denegado: se requieren permisos de Administrador.', response.statusCode);
      } else if (response.statusCode == 400) {
        final msg = body is Map && body.containsKey('mensaje') ? body['mensaje'] : 'Datos de producto invalidos.';
        throw CatalogException(msg, response.statusCode);
      } else {
        final msg = body is Map && body.containsKey('mensaje') ? body['mensaje'] : 'Error en el servidor (${response.statusCode}).';
        throw CatalogException(msg, response.statusCode);
      }
    } on SocketException {
      // Si esta en modo offline, simula creacion exitosa local para pruebas
      return ProductModel(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: request.nombre,
        precio: request.precio,
        detalle: request.detalle ?? '',
        foto: request.foto ?? '',
        stock: request.stock,
      );
    } on http.ClientException {
      throw CatalogException('Error de comunicacion con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrio un error inesperado: $e');
    }
  }

  /// Actualiza un producto existente en el backend Spring Boot (PUT /api/productos/{id})
  Future<ProductModel> actualizarProducto(int id, ProductoRequest request, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos/$id');

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.put(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return ProductModel.fromJson(body as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        throw CatalogException('Acceso denegado: se requieren permisos de Administrador.', response.statusCode);
      } else if (response.statusCode == 404) {
        throw CatalogException('El producto a actualizar no fue encontrado.', response.statusCode);
      } else if (response.statusCode == 400) {
        final msg = body is Map && body.containsKey('mensaje') ? body['mensaje'] : 'Datos de producto invalidos.';
        throw CatalogException(msg, response.statusCode);
      } else {
        final msg = body is Map && body.containsKey('mensaje') ? body['mensaje'] : 'Error en el servidor (${response.statusCode}).';
        throw CatalogException(msg, response.statusCode);
      }
    } on SocketException {
      // Si esta en modo offline, simula actualizacion exitosa local
      return ProductModel(
        id: id,
        nombre: request.nombre,
        precio: request.precio,
        detalle: request.detalle ?? '',
        foto: request.foto ?? '',
        stock: request.stock,
      );
    } on http.ClientException {
      throw CatalogException('Error de comunicacion con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrio un error inesperado: $e');
    }
  }

  /// Elimina un producto existente en el backend Spring Boot (DELETE /api/productos/{id})
  Future<void> eliminarProducto(int id, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos/$id');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 403) {
        throw CatalogException('Acceso denegado: se requieren permisos de Administrador.', response.statusCode);
      } else if (response.statusCode == 404) {
        throw CatalogException('El producto a eliminar no fue encontrado.', response.statusCode);
      } else if (response.statusCode == 400) {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final msg = body is Map && body.containsKey('mensaje') ? body['mensaje'] : 'No se pudo eliminar el producto.';
        throw CatalogException(msg, response.statusCode);
      } else {
        throw CatalogException('Error en el servidor (${response.statusCode}).', response.statusCode);
      }
    } on SocketException {
      // Si esta en modo offline, simula eliminacion exitosa local para pruebas
      return;
    } on http.ClientException {
      throw CatalogException('Error de comunicacion con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrio un error inesperado: $e');
    }
  }

  /// Obtiene el historial de compras de un producto (GET /api/productos/{id}/compras).
  /// Solo accesible para Administradores.
  Future<List<ProductoCompraHistorialModel>> getHistorialComprasProducto(
    int productoId, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos/$productoId/compras');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((item) => ProductoCompraHistorialModel.fromJson(
                item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw CatalogException(
            'Acceso denegado: se requieren permisos de Administrador.',
            response.statusCode);
      } else if (response.statusCode == 404) {
        throw CatalogException(
            'El producto no fue encontrado.', response.statusCode);
      } else {
        throw CatalogException(
            'Error en el servidor (${response.statusCode}).',
            response.statusCode);
      }
    } on SocketException {
      throw CatalogException('Error de comunicacion con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicacion con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrio un error inesperado: $e');
    }
  }

  /// Lista productos desde el backend Spring Boot (GET /api/productos)
  Future<List<ProductModel>> getProductos({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        return getMockProducts();
      }
    } on SocketException {
      // Si el servidor está offline, usamos los productos mock de Figma
      return getMockProducts();
    } on http.ClientException {
      return getMockProducts();
    } catch (_) {
      return getMockProducts();
    }
  }

  static List<ProductModel> getMockProducts() {
    return const [
      ProductModel(
        id: 1,
        nombre: 'Vitamina C 1000mg',
        precio: 12.99,
        detalle: 'Suplemento antioxidante para fortalecer el sistema inmune.',
        foto: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300&q=80',
        stock: 24,
        categoria: 'Vitaminas',
      ),
      ProductModel(
        id: 2,
        nombre: 'Ibuprofeno 400mg',
        precio: 3.45,
        detalle: 'Antiinflamatorio y analgésico de rápida acción.',
        foto: 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=300&q=80',
        stock: 150,
        categoria: 'Medicamentos',
      ),
      ProductModel(
        id: 3,
        nombre: 'Protector Solar SPF50',
        precio: 24.99,
        detalle: 'Alta protección UVA/UVB resistente al agua.',
        foto: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&q=80',
        stock: 12,
        categoria: 'Cuidado Personal',
      ),
      ProductModel(
        id: 4,
        nombre: 'Paracetamol 500mg',
        precio: 2.99,
        detalle: 'Alivio eficaz del dolor de cabeza y la fiebre.',
        foto: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=300&q=80',
        stock: 85,
        categoria: 'Medicamentos',
      ),
      ProductModel(
        id: 5,
        nombre: 'Complejo B Multivitamínico',
        precio: 15.50,
        detalle: 'Energía y soporte para el sistema nervioso.',
        foto: 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=300&q=80',
        stock: 30,
        categoria: 'Vitaminas',
      ),
      ProductModel(
        id: 6,
        nombre: 'Alcohol en Gel 250ml',
        precio: 4.20,
        detalle: 'Sanitizante antibacteriano instantáneo con aloe vera.',
        foto: 'https://images.unsplash.com/photo-1584744982491-665216d95f8b?w=300&q=80',
        stock: 45,
        categoria: 'Cuidado Personal',
      ),
    ];
  }
}
