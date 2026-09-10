import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../routing/app_navigator.dart';

/// Pantalla de perfil del cliente, adaptada del diseño de Figma "Perfil"
/// a los widgets, colores y navegación ya usados en el resto de la app.
class ProfileScreen extends StatefulWidget {
  final String token;
  final String nombre;
  final String email;
  final AuthService? authService;
  final CartService? cartService;

  const ProfileScreen({
    super.key,
    required this.token,
    required this.nombre,
    required this.email,
    this.authService,
    this.cartService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  late final CartService _cartService;

  int _cartItemCount = 0;
  bool _isLoggingOut = false;

  static const List<(IconData, String)> _menuItems = [
    (Icons.person_outline_rounded, 'Mis datos'),
    (Icons.location_on_outlined, 'Dirección de entrega'),
    (Icons.credit_card_outlined, 'Método de pago'),
    (Icons.notifications_outlined, 'Notificaciones'),
    (Icons.help_outline_rounded, 'Ayuda y soporte'),
  ];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _cartService = widget.cartService ?? CartService();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (mounted) setState(() => _cartItemCount = cart.cantidadUnidades);
    } on CartException catch (_) {}
  }

  String get _iniciales {
    final partes = widget.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1))
        .toUpperCase();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await _authService.logout(widget.token);
    if (!mounted) return;
    AppNavigator.toLoginAndClearStack(context);
  }

  void _proximamente(String funcion) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcion estará disponible próximamente.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onNavTap(int index) async {
    if (index == 4) return; // ya estamos en Perfil
    if (index == 2) {
      await AppNavigator.toCart(context, token: widget.token);
      _refreshCartCount();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMenu(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 4,
        cartCount: _cartItemCount,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _iniciales,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.nombre.isNotEmpty ? widget.nombre : 'Usuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _menuItems.length; i++)
            InkWell(
              onTap: () => _proximamente(_menuItems[i].$2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: i == _menuItems.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            width: 1,
                            color: AppColors.border,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _menuItems[i].$1,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _menuItems[i].$2,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textSubtle,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _isLoggingOut ? null : _logout,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
