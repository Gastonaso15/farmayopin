import 'auth_response.dart';

/// Modelo que representa una sesión de usuario guardada localmente en SQLite.
class UserSessionModel {
  final String email;
  final String nombre;
  final String token;
  final UserRole rol;
  final String? passwordHash;
  final bool rememberMe;
  final bool isActive;
  final DateTime lastLogin;

  const UserSessionModel({
    required this.email,
    required this.nombre,
    required this.token,
    required this.rol,
    this.passwordHash,
    this.rememberMe = false,
    this.isActive = false,
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email.trim().toLowerCase(),
      'nombre': nombre,
      'token': token,
      'rol': rol.name,
      'password_hash': passwordHash,
      'remember_me': rememberMe ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin.toIso8601String(),
    };
  }

  factory UserSessionModel.fromMap(Map<String, dynamic> map) {
    return UserSessionModel(
      email: map['email'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      token: map['token'] as String? ?? '',
      rol: UserRole.fromString(map['rol'] as String? ?? 'CLIENTE'),
      passwordHash: map['password_hash'] as String?,
      rememberMe: (map['remember_me'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      lastLogin: DateTime.tryParse(map['last_login'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AuthResponse toAuthResponse() {
    return AuthResponse(
      token: token,
      email: email,
      nombre: nombre,
      rol: rol,
    );
  }
}
