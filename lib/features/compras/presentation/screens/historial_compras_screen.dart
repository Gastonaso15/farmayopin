import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/local/compra_local_database.dart';
import '../../../../data/models/compra_model.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../data/services/compra_service.dart';
import '../../../../routing/app_navigator.dart';

/// Lista del historial de compras del cliente (GET /api/compras). Cada
/// tarjeta lleva al detalle (DetalleCompraScreen).
///
/// Soporta persistencia y replicación local en SQLite, permitiendo consultar
/// las compras previas del usuario cuando no hay conexión a internet o el
/// servidor se encuentra inaccesible.
class HistorialComprasScreen extends StatefulWidget {
  final String? token;
  final String? userEmail;
  final CompraService? compraService;
  final CartService? cartService;
  final bool isOfflineMode;

  const HistorialComprasScreen({
    super.key,
    this.token,
    this.userEmail,
    this.compraService,
    this.cartService,
    this.isOfflineMode = false,
  });

  @override
  State<HistorialComprasScreen> createState() =>
      _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  late final CompraService _compraService;
  late final CartService _cartService;

  List<CompraModel> _compras = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _offlineNotice;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _compraService = widget.compraService ?? CompraService();
    _cartService = widget.cartService ?? CartService();
    _loadHistorial();
    if (!widget.isOfflineMode) {
      _refreshCartCount();
    }
  }

  Future<void> _refreshCartCount() async {
    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (mounted) setState(() => _cartItemCount = cart.cantidadUnidades);
    } on CartException catch (_) {}
  }

  Future<void> _loadHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (widget.isOfflineMode) {
      try {
        final localDb = _compraService.localDatabase;
        final localCompras =
            await localDb.getComprasByUser(widget.userEmail ?? '');
        if (!mounted) return;
        setState(() {
          _compras = localCompras;
          _isOffline = true;
          _offlineNotice =
              'Modo sin conexión: mostrando historial guardado localmente en SQLite.';
          _isLoading = false;
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Error al cargar compras locales: $e';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final result = await _compraService.getHistorialResult(
        token: widget.token,
        userEmail: widget.userEmail,
      );
      if (!mounted) return;
      setState(() {
        _compras = result.compras;
        _isOffline = result.isFromLocalDatabase;
        _offlineNotice = result.noticeMessage;
        _isLoading = false;
      });
    } on CompraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _onNavTap(int index) async {
    if (widget.isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta función requiere conexión con el servidor.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppNavigator.goToClientTab(
      context,
      index,
      currentIndex: AppNavigator.tabHistorial,
      token: widget.token,
      email: widget.userEmail,
    );
  }

  static const List<String> _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final esHoy = fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;
    if (esHoy) {
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return 'Hoy, $hora:$minuto';
    }
    return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            widget.isOfflineMode
                ? AppScreenHeader(
                    title: 'Historial (Sin conexión)',
                    onBack: () => AppNavigator.toLoginAndClearStack(context),
                    trailing: IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      onPressed: () async {
                        await CompraLocalDatabase().clearActiveSession();
                        if (!context.mounted) return;
                        AppNavigator.toLoginAndClearStack(context);
                      },
                    ),
                  )
                : const AppScreenHeader(title: 'Historial de Compras'),
            if (_isOffline && !_isLoading && _error == null)
              _buildOfflineBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: widget.isOfflineMode
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modo sin conexión',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await CompraLocalDatabase().clearActiveSession();
                      if (!context.mounted) return;
                      AppNavigator.toLoginAndClearStack(context);
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ClientBottomNav(
              currentIndex: 3,
              cartCount: _cartItemCount,
              onTap: _onNavTap,
            ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFC2410C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _offlineNotice ??
                  'Modo sin conexión: mostrando historial guardado localmente en SQLite.',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadHistorial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_compras.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.textSubtle,
              ),
              SizedBox(height: 12),
              Text(
                'Todavía no tienes compras.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHistorial,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        itemCount: _compras.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildCompraCard(_compras[index]),
      ),
    );
  }

  Widget _buildCompraCard(CompraModel compra) {
    final cantidadItems = compra.items.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppNavigator.toDetalleCompra(
        context,
        compra: compra,
        token: widget.token,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${compra.id}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFecha(compra.fecha),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$cantidadItems ${cantidadItems == 1 ? 'producto' : 'productos'}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${compra.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
