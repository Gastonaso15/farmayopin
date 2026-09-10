import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../catalog/data/services/catalog_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  final String nombre;
  final CatalogService? catalogService;
  final AuthService? authService;

  const AdminDashboardScreen({
    super.key,
    required this.token,
    required this.nombre,
    this.catalogService,
    this.authService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final CatalogService _catalogService;
  late final AuthService _authService;

  int? _totalProductos;
  int? _stockBajo;
  bool _isLoggingOut = false;

  static const int _umbralStockBajo = 10;

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? CatalogService();
    _authService = widget.authService ?? AuthService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final productos = await _catalogService.getProductos(token: widget.token);
    if (!mounted) return;
    setState(() {
      _totalProductos = productos.length;
      _stockBajo = productos.where((p) => p.stock < _umbralStockBajo).length;
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    await _authService.logout(widget.token);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  children: [
                    _buildWelcome(),
                    const SizedBox(height: 24),
                    _buildStatCard(
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFF0F9FF),
                      iconColor: AppColors.link,
                      value: _totalProductos,
                      label: 'Total Productos',
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: AppColors.error,
                      value: _stockBajo,
                      label: 'Productos Stock Bajo',
                      trailing: (_stockBajo ?? 0) > 0 ? _criticoPill() : null,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.receipt_long_outlined,
                      iconBg: const Color(0xFFF0FDFA),
                      iconColor: AppColors.primary,
                      value: null,
                      label: 'Compras Hoy',
                    ),
                    const SizedBox(height: 24),
                    _buildActions(),
                    const SizedBox(height: 12),
                    _buildLogout(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(width: 1, color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Farma',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Y',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Opin',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'PANEL DE ADMINISTRACIÓN',
                style: TextStyle(
                  color: AppColors.link,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido, ${widget.nombre.isNotEmpty ? widget.nombre : 'Admin'}!',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Panel de gestión de FarmaYopin',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required int? value,
    required String label,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value?.toString() ?? '—',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _criticoPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Crítico',
        style: TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones de gestión',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'Gestionar Productos',
          filled: true,
          onTap: () => _showSnack('Gestionar Productos próximamente.'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.receipt_long_outlined,
          label: 'Historial de Compras',
          filled: false,
          onTap: () => _showSnack('Historial de compras próximamente.'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: fg),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout() {
    return Center(
      child: InkWell(
        onTap: _isLoggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoggingOut)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              else
                const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
              const SizedBox(width: 8),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
