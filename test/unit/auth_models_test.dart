import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/data/models/auth_response.dart';
import 'package:farmayopin/data/models/login_request.dart';
import 'package:farmayopin/data/models/register_request.dart';

void main() {
  group('Auth Models Test', () {
    test('LoginRequest toJson genera el formato esperado por Spring Boot', () {
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );
      final json = request.toJson();
      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');
    });

    test('RegisterRequest toJson genera el formato esperado por Spring Boot', () {
      const request = RegisterRequest(
        nombre: 'Gastón Pérez',
        email: 'gaston@utec.edu.uy',
        password: 'password123',
      );
      final json = request.toJson();
      expect(json['nombre'], 'Gastón Pérez');
      expect(json['email'], 'gaston@utec.edu.uy');
      expect(json['password'], 'password123');
    });

    test('AuthResponse fromJson mapea rol CLIENTE correctamente', () {
      final json = {
        'id': 1,
        'nombre': 'Gastón Pérez',
        'email': 'gaston@utec.edu.uy',
        'rol': 'CLIENTE',
        'token': 'jwt-sample-token',
      };
      final response = AuthResponse.fromJson(json);
      expect(response.id, 1);
      expect(response.nombre, 'Gastón Pérez');
      expect(response.email, 'gaston@utec.edu.uy');
      expect(response.rol, UserRole.cliente);
      expect(response.token, 'jwt-sample-token');
    });

    test('AuthResponse fromJson mapea rol ADMIN correctamente', () {
      final json = {
        'id': 2,
        'nombre': 'Admin User',
        'email': 'admin@utec.edu.uy',
        'rol': 'ADMIN',
        'token': 'admin-jwt-token',
      };
      final response = AuthResponse.fromJson(json);
      expect(response.rol, UserRole.admin);
      expect(response.rol.toDisplayString(), 'Administrador');
    });
  });
}
