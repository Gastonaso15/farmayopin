import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/direccion_model.dart';

class DireccionException implements Exception {
  final String message;
  final int? statusCode;

  DireccionException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class DireccionService {
  final http.Client _client;

  DireccionService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String? token) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Obtiene la lista de direcciones del usuario desde GET /api/direcciones
  Future<List<DireccionModel>> getDirecciones({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/direcciones');

    try {
      final response = await _client.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((item) => DireccionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw DireccionException(
          'Error al obtener direcciones (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw DireccionException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is DireccionException) rethrow;
      throw DireccionException('Error inesperado: $e');
    }
  }

  /// Crea una nueva dirección en POST /api/direcciones
  Future<DireccionModel> crearDireccion({
    required DireccionModel direccion,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/direcciones');

    try {
      final response = await _client.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(direccion.toJson()),
      );

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DireccionModel.fromJson(body as Map<String, dynamic>);
      } else {
        final msg = body is Map && body.containsKey('mensaje')
            ? body['mensaje']
            : 'Error al registrar dirección (${response.statusCode})';
        throw DireccionException(msg.toString(), response.statusCode);
      }
    } on SocketException {
      throw DireccionException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is DireccionException) rethrow;
      throw DireccionException('Error al crear dirección: $e');
    }
  }

  /// Actualiza una dirección existente en PUT /api/direcciones/{id}
  Future<DireccionModel> actualizarDireccion({
    required DireccionModel direccion,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/direcciones/${direccion.id}');

    try {
      final response = await _client.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(direccion.toJson()),
      );

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return DireccionModel.fromJson(body as Map<String, dynamic>);
      } else {
        final msg = body is Map && body.containsKey('mensaje')
            ? body['mensaje']
            : 'Error al actualizar dirección (${response.statusCode})';
        throw DireccionException(msg.toString(), response.statusCode);
      }
    } on SocketException {
      throw DireccionException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is DireccionException) rethrow;
      throw DireccionException('Error al actualizar dirección: $e');
    }
  }

  /// Elimina una dirección en DELETE /api/direcciones/{id}
  Future<void> eliminarDireccion({
    required String id,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/direcciones/$id');

    try {
      final response = await _client.delete(uri, headers: _headers(token));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DireccionException(
          'Error al eliminar dirección (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw DireccionException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is DireccionException) rethrow;
      throw DireccionException('Error al eliminar dirección: $e');
    }
  }

  /// Marca una dirección como predeterminada en PATCH /api/direcciones/{id}/principal
  Future<DireccionModel> marcarComoPrincipal({
    required String id,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/direcciones/$id/principal');

    try {
      final response = await _client.patch(uri, headers: _headers(token));

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return DireccionModel.fromJson(body as Map<String, dynamic>);
      } else {
        throw DireccionException(
          'Error al cambiar dirección principal (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw DireccionException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is DireccionException) rethrow;
      throw DireccionException('Error al marcar dirección principal: $e');
    }
  }
}
