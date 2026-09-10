enum UserRole {
  cliente,
  admin;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.cliente;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'CLIENTE':
      default:
        return UserRole.cliente;
    }
  }

  String toDisplayString() {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.cliente:
        return 'Cliente';
    }
  }
}

class AuthResponse {
  final int? id;
  final String nombre;
  final String email;
  final UserRole rol;
  final String token;

  const AuthResponse({
    this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: UserRole.fromString(json['rol'] as String?),
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol == UserRole.admin ? 'ADMIN' : 'CLIENTE',
      'token': token,
    };
  }
}
