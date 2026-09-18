import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../local/compra_local_database.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Realiza el login en el backend Spring Boot
  Future<AuthResponse> login(LoginRequest request) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
    );

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseBody as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        final message =
            responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Correo o contraseña incorrectos.';
        throw AuthException(message, response.statusCode);
      } else if (response.statusCode == 400) {
        final message =
            responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Solicitud inválida. Revisa los datos ingresados.';
        throw AuthException(message, response.statusCode);
      } else {
        final message =
            responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Error en el servidor (${response.statusCode}).';
        throw AuthException(message, response.statusCode);
      }
    } on SocketException {
      throw AuthException(
        'No se pudo conectar con el servidor. Verifica tu conexión o que el backend esté en ejecución.',
      );
    } on http.ClientException {
      throw AuthException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Ocurrió un error inesperado: $e');
    }
  }

  /// Realiza el registro de un nuevo usuario en el backend Spring Boot
  Future<AuthResponse> register(RegisterRequest request) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}',
    );

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(responseBody as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final message =
            responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Los datos de registro no son válidos o el correo ya se encuentra registrado.';
        throw AuthException(message, response.statusCode);
      } else {
        final message =
            responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Error en el servidor (${response.statusCode}).';
        throw AuthException(message, response.statusCode);
      }
    } on SocketException {
      throw AuthException(
        'No se pudo conectar con el servidor. Verifica tu conexión o que el backend esté en ejecución.',
      );
    } on http.ClientException {
      throw AuthException('Error de comunicación con el servidor.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Ocurrió un error inesperado: $e');
    }
  }

  /// Invalida el token activo en el backend. Best-effort: la sesión se cierra
  /// localmente aunque la petición falle.
  Future<void> logout(String token) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}',
    );

    try {
      await _client.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  /// Comprueba rápidamente si el servidor backend se encuentra alcanzable.
  Future<bool> checkServerConnection({Duration timeout = const Duration(seconds: 2)}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos');
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      // Cualquier respuesta del servidor (incluso 401/403) demuestra que hay conectividad
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  /// Realiza la autenticación local offline contra la base de datos SQLite.
  /// Retorna un [AuthResponse] reconstruido a partir de la sesión guardada
  /// o lanza un [AuthException] si las credenciales no coinciden o no existen.
  Future<AuthResponse> loginLocal({
    required String email,
    required String password,
    CompraLocalDatabase? localDb,
  }) async {
    final db = localDb ?? CompraLocalDatabase();
    final isValid = await db.validateLocalCredentials(email, password);
    if (!isValid) {
      throw AuthException(
        'Credenciales inválidas o no existen datos guardados localmente para este usuario.',
      );
    }

    final session = await db.getSessionByEmail(email);
    if (session == null) {
      throw AuthException(
        'No se encontró la sesión local guardada para este usuario.',
      );
    }

    return session.toAuthResponse();
  }
}
