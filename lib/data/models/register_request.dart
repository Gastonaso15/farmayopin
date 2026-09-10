class RegisterRequest {
  final String nombre;
  final String email;
  final String password;

  const RegisterRequest({
    required this.nombre,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'email': email, 'password': password};
  }
}
