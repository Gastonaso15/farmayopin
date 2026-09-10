import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/compra_model.dart';

class CompraException implements Exception {
  final String message;
  final int? statusCode;

  CompraException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CompraService {
  final http.Client _client;

  CompraService({http.Client? client}) : _client = client ?? http.Client();

  /// Obtiene el historial de compras del usuario autenticado (GET /api/compras)
  Future<List<CompraModel>> getHistorial({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/compras');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((item) => CompraModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw CompraException(
          'Tu sesión expiró. Inicia sesión nuevamente.',
          response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw CompraException(
          'Acceso denegado: solo los clientes tienen historial de compras.',
          response.statusCode,
        );
      } else {
        throw CompraException(
          'Error en el servidor (${response.statusCode}).',
          response.statusCode,
        );
      }
    } on SocketException {
      throw CompraException(
        'No se pudo conectar con el servidor. Verifica tu conexión o que el backend esté en ejecución.',
      );
    } on http.ClientException {
      throw CompraException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is CompraException) rethrow;
      throw CompraException('Ocurrió un error inesperado: $e');
    }
  }
}
