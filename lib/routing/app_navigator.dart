import 'package:flutter/material.dart';

import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../data/models/auth_response.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../data/models/cart_model.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/cart/presentation/screens/confirm_purchase_screen.dart';
import '../data/models/product_model.dart';
import '../features/catalog/presentation/screens/catalog_screen.dart';
import '../features/catalog/presentation/screens/create_product_screen.dart';
import '../features/catalog/presentation/screens/edit_product_screen.dart';
import '../features/catalog/presentation/screens/manage_products_screen.dart';
import '../features/catalog/presentation/screens/product_detail_admin_screen.dart';
import '../features/catalog/presentation/screens/product_detail_client_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../data/models/compra_model.dart';
import '../features/compras/presentation/screens/detalle_compra_screen.dart';
import '../features/compras/presentation/screens/historial_compras_screen.dart';

class AppNavigator {
  AppNavigator._();

  static void toHomeForRole(BuildContext context, AuthResponse auth) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.rol == UserRole.admin
            ? AdminDashboardScreen(token: auth.token, nombre: auth.nombre)
            : CatalogScreen(
                token: auth.token,
                nombre: auth.nombre,
                email: auth.email,
              ),
      ),
    );
  }

  static void toLoginAndClearStack(BuildContext context) {
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
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfirmPurchaseScreen(cart: cart, token: token),
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

  static Future<void> toHistorial(BuildContext context, {String? token}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistorialComprasScreen(token: token),
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
}
