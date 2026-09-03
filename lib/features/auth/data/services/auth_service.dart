import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

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
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseBody as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        final message = responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Correo o contraseña incorrectos.';
        throw AuthException(message, response.statusCode);
      } else if (response.statusCode == 400) {
        final message = responseBody is Map && responseBody.containsKey('mensaje')
            ? responseBody['mensaje']
            : 'Solicitud inválida. Revisa los datos ingresados.';
        throw AuthException(message, response.statusCode);
      } else {
        final message = responseBody is Map && responseBody.containsKey('mensaje')
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
}
