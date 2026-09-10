import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/cart_model.dart';

class CartException implements Exception {
  final String message;
  final int? statusCode;

  CartException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CartService {
  final http.Client _client;

  CartService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<CartModel> getCarrito({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/carrito');
    return _send(() => _client.get(uri, headers: _headers(token)));
  }

  Future<CartModel> agregarItem({
    required int productoId,
    required int cantidad,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/carrito/items');
    return _send(
      () => _client.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'productoId': productoId, 'cantidad': cantidad}),
      ),
    );
  }

  Future<CartModel> actualizarCantidad({
    required int itemId,
    required int cantidad,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/carrito/items/$itemId');
    return _send(
      () => _client.put(
        uri,
        headers: _headers(token),
        body: jsonEncode({'cantidad': cantidad}),
      ),
    );
  }

  Future<CartModel> eliminarItem({required int itemId, String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/carrito/items/$itemId');
    return _send(() => _client.delete(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> pagarCarrito({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/carrito/pago');

    try {
      final response = await _client.post(uri, headers: _headers(token));
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return body as Map<String, dynamic>;
      }
      throw _mapError(response.statusCode, body);
    } on SocketException {
      throw CartException(_offlineMessage);
    } on http.ClientException {
      throw CartException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CartException) rethrow;
      throw CartException('Ocurrió un error inesperado: $e');
    }
  }

  Future<CartModel> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CartModel.fromJson(body as Map<String, dynamic>);
      }
      throw _mapError(response.statusCode, body);
    } on SocketException {
      throw CartException(_offlineMessage);
    } on http.ClientException {
      throw CartException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CartException) rethrow;
      throw CartException('Ocurrió un error inesperado: $e');
    }
  }

  CartException _mapError(int statusCode, dynamic body) {
    final backendMsg = body is Map && body['mensaje'] != null
        ? body['mensaje'].toString()
        : null;

    switch (statusCode) {
      case 400:
        return CartException(
          backendMsg ?? 'No hay stock suficiente para completar la operación.',
          statusCode,
        );
      case 401:
        return CartException(
          'Tu sesión expiró. Inicia sesión nuevamente.',
          statusCode,
        );
      case 403:
        return CartException(
          'Acceso denegado: solo los clientes pueden usar el carrito.',
          statusCode,
        );
      case 404:
        return CartException(
          backendMsg ?? 'El producto o ítem no fue encontrado.',
          statusCode,
        );
      default:
        return CartException(
          backendMsg ?? 'Error en el servidor ($statusCode).',
          statusCode,
        );
    }
  }

  static const String _offlineMessage =
      'No se pudo conectar con el servidor. Verifica tu conexión o que el backend esté en ejecución.';
}
