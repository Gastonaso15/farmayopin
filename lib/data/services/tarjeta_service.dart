import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/tarjeta_model.dart';

class TarjetaException implements Exception {
  final String message;
  final int? statusCode;

  TarjetaException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class TarjetaService {
  final http.Client _client;

  TarjetaService({http.Client? client}) : _client = client ?? http.Client();

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

  /// Obtiene la lista de tarjetas del usuario desde GET /api/tarjetas
  Future<List<TarjetaModel>> getTarjetas({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/tarjetas');

    try {
      final response = await _client.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((item) => TarjetaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw TarjetaException(
          'Error al obtener tarjetas (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw TarjetaException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is TarjetaException) rethrow;
      throw TarjetaException('Error inesperado: $e');
    }
  }

  /// Registra una nueva tarjeta en POST /api/tarjetas
  Future<TarjetaModel> crearTarjeta({
    required TarjetaModel tarjeta,
    String? numeroCompleto,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/tarjetas');

    try {
      final payload = tarjeta.toJson();
      if (numeroCompleto != null && numeroCompleto.trim().isNotEmpty) {
        payload['numeroTarjeta'] = numeroCompleto;
      }

      final response = await _client.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TarjetaModel.fromJson(body as Map<String, dynamic>);
      } else {
        final msg = body is Map && body.containsKey('mensaje')
            ? body['mensaje']
            : 'Error al registrar tarjeta (${response.statusCode})';
        throw TarjetaException(msg.toString(), response.statusCode);
      }
    } on SocketException {
      throw TarjetaException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is TarjetaException) rethrow;
      throw TarjetaException('Error al registrar tarjeta: $e');
    }
  }

  /// Elimina una tarjeta en DELETE /api/tarjetas/{id}
  Future<void> eliminarTarjeta({
    required String id,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/tarjetas/$id');

    try {
      final response = await _client.delete(uri, headers: _headers(token));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw TarjetaException(
          'Error al eliminar tarjeta (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw TarjetaException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is TarjetaException) rethrow;
      throw TarjetaException('Error al eliminar tarjeta: $e');
    }
  }

  /// Marca una tarjeta como predeterminada en PATCH /api/tarjetas/{id}/principal
  Future<TarjetaModel> marcarComoPrincipal({
    required String id,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/tarjetas/$id/principal');

    try {
      final response = await _client.patch(uri, headers: _headers(token));

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return TarjetaModel.fromJson(body as Map<String, dynamic>);
      } else {
        throw TarjetaException(
          'Error al cambiar tarjeta principal (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw TarjetaException('No se pudo conectar con el servidor.');
    } catch (e) {
      if (e is TarjetaException) rethrow;
      throw TarjetaException('Error al marcar tarjeta principal: $e');
    }
  }
}
