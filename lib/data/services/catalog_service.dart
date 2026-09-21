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
      throw CatalogException('No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrió un error inesperado: $e');
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
      throw CatalogException('No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrió un error inesperado: $e');
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
      throw CatalogException('No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrió un error inesperado: $e');
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
      throw CatalogException('No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrió un error inesperado: $e');
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
        return list
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final msg = body is Map && body.containsKey('mensaje')
            ? body['mensaje']
            : 'Error al obtener productos (${response.statusCode}).';
        throw CatalogException(msg.toString(), response.statusCode);
      }
    } on SocketException {
      throw CatalogException('No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw CatalogException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CatalogException) rethrow;
      throw CatalogException('Ocurrió un error inesperado: $e');
    }
  }
}
