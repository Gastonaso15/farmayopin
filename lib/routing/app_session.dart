/// Datos de la sesión activa en memoria.
///
/// Permite que la barra de navegación inferior pueda llevar al usuario a
/// cualquier sección (Inicio, Catálogo, Carrito, Historial, Perfil) desde
/// cualquier pantalla, sin que cada una tenga que recibir y reenviar el
/// token, el nombre y el email.
class AppSession {
  AppSession._();

  static String token = '';
  static String nombre = '';
  static String email = '';

  static void start({
    required String token,
    required String nombre,
    required String email,
  }) {
    AppSession.token = token;
    AppSession.nombre = nombre;
    AppSession.email = email;
  }

  static void clear() {
    token = '';
    nombre = '';
    email = '';
  }
}
