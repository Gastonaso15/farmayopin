import 'package:flutter/material.dart';

import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../data/models/auth_response.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../data/models/cart_model.dart';
import '../data/services/cart_service.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/cart/presentation/screens/confirm_purchase_screen.dart';
import '../data/models/product_model.dart';
import '../data/services/catalog_service.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/catalog/presentation/screens/catalog_screen.dart';
import '../features/catalog/presentation/screens/create_product_screen.dart';
import '../features/catalog/presentation/screens/edit_product_screen.dart';
import '../features/catalog/presentation/screens/manage_products_screen.dart';
import '../features/catalog/presentation/screens/product_detail_admin_screen.dart';
import '../features/catalog/presentation/screens/product_detail_client_screen.dart';
import '../features/catalog/presentation/screens/historial_compras_producto_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/mis_datos_screen.dart';
import '../features/profile/presentation/screens/direccion_entrega_screen.dart';
import '../features/profile/presentation/screens/metodo_pago_screen.dart';
import '../data/models/compra_model.dart';
import '../data/services/compra_service.dart';
import '../data/services/tarjeta_service.dart';
import '../data/services/direccion_service.dart';
import '../features/compras/presentation/screens/detalle_compra_screen.dart';
import '../features/compras/presentation/screens/historial_compras_screen.dart';
import 'app_session.dart';

class AppNavigator {
  AppNavigator._();

  /// Índices de las secciones de la barra de navegación inferior.
  static const int tabInicio = 0;
  static const int tabCatalogo = 1;
  static const int tabCarrito = 2;
  static const int tabHistorial = 3;
  static const int tabPerfil = 4;

  /// Lleva al usuario a una sección de la barra inferior desde cualquier
  /// pantalla. Arma la pila como [Inicio, Sección], de modo que la flecha de
  /// volver siempre regresa a Inicio y la pila nunca crece sin control.
  ///
  /// Si [currentIndex] coincide con [index] no hace nada (ya está ahí).
  /// Los datos de sesión que no se pasen se toman de [AppSession].
  static void goToClientTab(
    BuildContext context,
    int index, {
    int? currentIndex,
    String? token,
    String? nombre,
    String? email,
    CatalogService? catalogService,
  }) {
    if (currentIndex != null && index == currentIndex) return;

    final t = (token != null && token.isNotEmpty) ? token : AppSession.token;
    final n = (nombre != null && nombre.isNotEmpty) ? nombre : AppSession.nombre;
    final e = (email != null && email.isNotEmpty) ? email : AppSession.email;
    final tokenOrNull = t.isEmpty ? null : t;

    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          token: tokenOrNull,
          nombre: n,
          email: e,
          catalogService: catalogService,
        ),
      ),
      (route) => false,
    );

    if (index == tabInicio) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) {
          switch (index) {
            case tabCatalogo:
              return CatalogScreen(
                token: tokenOrNull,
                nombre: n,
                email: e,
                catalogService: catalogService,
              );
            case tabCarrito:
              return CartScreen(token: tokenOrNull);
            case tabHistorial:
              return HistorialComprasScreen(token: tokenOrNull, userEmail: e);
            case tabPerfil:
            default:
              return ProfileScreen(token: t, nombre: n, email: e);
          }
        },
      ),
    );
  }

  static void toHomeForRole(BuildContext context, AuthResponse auth) {
    AppSession.start(
      token: auth.token,
      nombre: auth.nombre,
      email: auth.email,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.rol == UserRole.admin
            ? AdminDashboardScreen(token: auth.token, nombre: auth.nombre)
            : HomeScreen(
                token: auth.token,
                nombre: auth.nombre,
                email: auth.email,
              ),
      ),
    );
  }

  static Future<void> toHome(
    BuildContext context, {
    required String token,
    required String nombre,
    required String email,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          token: token,
          nombre: nombre,
          email: email,
        ),
      ),
    );
  }

  static Future<void> toCatalog(
    BuildContext context, {
    String? token,
    String nombre = '',
    String email = '',
    String? initialCategory,
    CatalogService? catalogService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogScreen(
          token: token,
          nombre: nombre,
          email: email,
          initialCategory: initialCategory,
          catalogService: catalogService,
        ),
      ),
    );
  }

  static void toLoginAndClearStack(BuildContext context) {
    AppSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static Future<void> toRegister(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  static Future<CartModel?> toCart(BuildContext context, {String? token}) {
    return Navigator.of(context).push<CartModel>(
      MaterialPageRoute(builder: (_) => CartScreen(token: token)),
    );
  }

  static Future<bool?> toConfirmPurchase(
    BuildContext context, {
    required CartModel cart,
    String? token,
    CartService? cartService,
    TarjetaService? tarjetaService,
    DireccionService? direccionService,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfirmPurchaseScreen(
          cart: cart,
          token: token,
          cartService: cartService,
          tarjetaService: tarjetaService,
          direccionService: direccionService,
        ),
      ),
    );
  }

  static Future<void> toProductDetailClient(
    BuildContext context, {
    required ProductModel product,
    String? token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailClientScreen(product: product, token: token),
      ),
    );
  }

  static Future<void> toManageProducts(
    BuildContext context, {
    required String token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageProductsScreen(token: token)),
    );
  }

  static Future<void> toProfile(
    BuildContext context, {
    required String token,
    required String nombre,
    required String email,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(token: token, nombre: nombre, email: email),
      ),
    );
  }

  static Future<void> toMisDatos(
    BuildContext context, {
    required String token,
    required String nombre,
    required String email,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MisDatosScreen(token: token, nombre: nombre, email: email),
      ),
    );
  }

  static Future<void> toDireccionEntrega(
    BuildContext context, {
    String? token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DireccionEntregaScreen(token: token),
      ),
    );
  }

  static Future<void> toMetodoPago(
    BuildContext context, {
    String? token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MetodoPagoScreen(token: token),
      ),
    );
  }

  static Future<void> toHistorial(
    BuildContext context, {
    String? token,
    String? userEmail,
    bool isOfflineMode = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistorialComprasScreen(
          token: token,
          userEmail: userEmail,
          isOfflineMode: isOfflineMode,
        ),
      ),
    );
  }

  static void toOfflineHistorial(
    BuildContext context, {
    required String userEmail,
    CompraService? compraService,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HistorialComprasScreen(
          userEmail: userEmail,
          isOfflineMode: true,
          compraService: compraService,
        ),
      ),
    );
  }

  static Future<void> toDetalleCompra(
    BuildContext context, {
    required CompraModel compra,
    String? token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleCompraScreen(compra: compra, token: token),
      ),
    );
  }

  static Future<ProductModel?> toCreateProduct(
    BuildContext context, {
    String? token,
  }) {
    return Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(builder: (_) => CreateProductScreen(token: token)),
    );
  }

  static Future<ProductModel?> toEditProduct(
    BuildContext context, {
    required ProductModel product,
    String? token,
  }) {
    return Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product, token: token),
      ),
    );
  }

  static Future<ProductModel?> toProductDetailAdmin(
    BuildContext context, {
    required ProductModel product,
    String? token,
  }) {
    return Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailAdminScreen(product: product, token: token),
      ),
    );
  }

  static Future<void> toHistorialProducto(
    BuildContext context, {
    required ProductModel product,
    String? token,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistorialComprasProductoScreen(
          product: product,
          token: token,
        ),
      ),
    );
  }
}
