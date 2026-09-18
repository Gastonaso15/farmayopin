import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../local/compra_local_database.dart';
import '../models/compra_model.dart';

class CompraException implements Exception {
  final String message;
  final int? statusCode;

  CompraException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Resultado de consulta de historial, indicando si los datos provienen del
/// backend remoto o del almacenamiento local offline SQLite.
class CompraHistorialResult {
  final List<CompraModel> compras;
  final bool isFromLocalDatabase;
  final String? noticeMessage;

  const CompraHistorialResult({
    required this.compras,
    this.isFromLocalDatabase = false,
    this.noticeMessage,
  });
}

class CompraService {
  final http.Client _client;
  final CompraLocalDatabase _localDb;

  CompraService({
    http.Client? client,
    CompraLocalDatabase? localDatabase,
  })  : _client = client ?? http.Client(),
        _localDb = localDatabase ?? CompraLocalDatabase();

  /// Obtiene el resultado del historial de compras con metadatos de sincronización.
  ///
  /// Si hay conexión exitosa con el servidor, descarga los datos y los replica
  /// en la base de datos SQLite local para el usuario [userEmail].
  /// Si se pierde la conexión o el servidor no responde, recurre automáticamente
  /// a los datos almacenados en SQLite.
  Future<CompraHistorialResult> getHistorialResult({
    String? token,
    String? userEmail,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/compras');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final compras = list
            .map((item) => CompraModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Determinar el email del usuario para la replicación local
        final effectiveEmail = (userEmail != null && userEmail.isNotEmpty)
            ? userEmail
            : (compras.isNotEmpty ? compras.first.clienteEmail : null);

        if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
          try {
            await _localDb.saveCompras(compras, userEmail: effectiveEmail);
          } catch (_) {
            // No interrumpir la visualización online si falla el guardado local
          }
        }

        return CompraHistorialResult(
          compras: compras,
          isFromLocalDatabase: false,
        );
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
        // En caso de error del servidor 5xx, intentar fallback a la base local
        if (response.statusCode >= 500) {
          final fallbackResult = await _tryGetLocalResult(
            userEmail: userEmail,
            noticeMessage:
                'El servidor no está disponible en este momento. Mostrando historial guardado localmente.',
          );
          if (fallbackResult != null) return fallbackResult;
        }

        throw CompraException(
          'Error en el servidor (${response.statusCode}).',
          response.statusCode,
        );
      }
    } on SocketException {
      return await _fallbackOrThrow(userEmail);
    } on http.ClientException {
      return await _fallbackOrThrow(userEmail);
    } on TimeoutException {
      return await _fallbackOrThrow(userEmail);
    } catch (e) {
      if (e is CompraException) rethrow;
      return await _fallbackOrThrow(userEmail);
    }
  }

  /// Obtiene la lista de compras directamente (conserva compatibilidad hacia atrás).
  Future<List<CompraModel>> getHistorial({
    String? token,
    String? userEmail,
  }) async {
    final result = await getHistorialResult(
      token: token,
      userEmail: userEmail,
    );
    return result.compras;
  }

  /// Guarda una compra en la base de datos local SQLite.
  Future<void> saveCompraLocal(
    CompraModel compra, {
    required String userEmail,
  }) async {
    await _localDb.saveCompra(compra, userEmail: userEmail);
  }

  /// Sincroniza explícitamente el historial de compras desde el servidor
  /// y lo replica en la base de datos local SQLite. Retorna la lista
  /// de compras sincronizadas o null si ocurrió un error de red/servidor.
  Future<List<CompraModel>?> syncHistorialConServidor({
    required String token,
    required String userEmail,
  }) async {
    if (token.isEmpty || userEmail.isEmpty) return null;
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/compras');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final compras = list
            .map((item) => CompraModel.fromJson(item as Map<String, dynamic>))
            .toList();
        await _localDb.saveCompras(compras, userEmail: userEmail);
        return compras;
      }
    } catch (_) {
      // Best-effort: no bloquear el flujo si la sincronización falla
    }
    return null;
  }

  Future<CompraHistorialResult?> _tryGetLocalResult({
    String? userEmail,
    required String noticeMessage,
  }) async {
    try {
      if (userEmail != null && userEmail.isNotEmpty) {
        final localCompras = await _localDb.getComprasByUser(userEmail);
        if (localCompras.isNotEmpty) {
          return CompraHistorialResult(
            compras: localCompras,
            isFromLocalDatabase: true,
            noticeMessage: noticeMessage,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<CompraHistorialResult> _fallbackOrThrow(String? userEmail) async {
    final cached = await _tryGetLocalResult(
      userEmail: userEmail,
      noticeMessage:
          'Sin conexión con el servidor. Mostrando historial guardado localmente.',
    );
    if (cached != null) {
      return cached;
    }
    throw CompraException(
      'No se pudo conectar con el servidor y no hay historial de compras guardado localmente. Verifica tu conexión.',
    );
  }
}
