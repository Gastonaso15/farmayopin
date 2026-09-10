import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../core/widgets/stepper_button.dart';
import '../../../../routing/app_navigator.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../data/models/cart_model.dart';
import '../../../../data/services/cart_service.dart';

class CartScreen extends StatefulWidget {
  final String? token;
  final CartService? cartService;

  const CartScreen({super.key, this.token, this.cartService});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartService _cartService;

  CartModel _cart = CartModel.empty;
  bool _isLoading = true;
  String? _errorMessage;

  final Set<int> _busyItems = {};

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } on CartException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItemModel item, int nuevaCantidad) async {
    if (nuevaCantidad < 0 || _busyItems.contains(item.id)) return;

    setState(() => _busyItems.add(item.id));
    try {
      final cart = await _cartService.actualizarCantidad(
        itemId: item.id,
        cantidad: nuevaCantidad,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() => _cart = cart);
    } on CartException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    final confirmed = await _confirmRemoval(item);
    if (confirmed != true || _busyItems.contains(item.id)) return;

    setState(() => _busyItems.add(item.id));
    try {
      final cart = await _cartService.eliminarItem(
        itemId: item.id,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() => _cart = cart);
      _showSnack('${item.nombreProducto} eliminado del carrito.');
    } on CartException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  Future<bool?> _confirmRemoval(CartItemModel item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: Text('¿Quitar "${item.nombreProducto}" de tu carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToConfirm() async {
    if (_cart.isEmpty) return;

    final paid = await AppNavigator.toConfirmPurchase(
      context,
      cart: _cart,
      token: widget.token,
    );

    if (paid == true && mounted) {
      setState(() => _cart = CartModel.empty);
      Navigator.of(context).pop(_cart);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_cart);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(
                title: 'Mi Carrito',
                onBack: () => Navigator.of(context).pop(_cart),
                trailing: _cart.isEmpty ? null : _buildItemsBadge(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        bottomNavigationBar: ClientBottomNav(
          currentIndex: 2,
          cartCount: _cart.cantidadUnidades,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0 || index == 1) {
      Navigator.of(context).pop(_cart);
    }
  }

  Widget _buildItemsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_cart.items.length} ${_cart.items.length == 1 ? 'Item' : 'Items'}',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_cart.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadCart,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          for (final item in _cart.items) ...[
            _buildCartItem(item),
            const SizedBox(height: 16),
          ],
          _buildSummary(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToConfirm,
              child: const Text('Pagar carrito'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final isBusy = _busyItems.contains(item.id);

    return Opacity(
      opacity: isBusy ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFFF3F4F6),
                child: item.imagenUrl.isNotEmpty
                    ? Image.network(
                        item.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _itemImageFallback(),
                      )
                    : _itemImageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombreProducto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.precioUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildQuantityStepper(item, isBusy),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isBusy ? null : () => _removeItem(item),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(CartItemModel item, bool isBusy) {
    return Row(
      children: [
        StepperButton(
          icon: Icons.remove_rounded,
          onTap: isBusy ? null : () => _updateQuantity(item, item.cantidad - 1),
        ),
        const SizedBox(width: 12),
        Text(
          '${item.cantidad}',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        StepperButton(
          icon: Icons.add_rounded,
          onTap: isBusy ? null : () => _updateQuantity(item, item.cantidad + 1),
        ),
      ],
    );
  }

  Widget _itemImageFallback() {
    return const Center(
      child: Icon(
        Icons.medication_rounded,
        size: 28,
        color: AppColors.textSubtle,
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: AppColors.textSubtle,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tu carrito está vacío',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agrega productos desde el catálogo para comenzar tu compra.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(_cart),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        width: 2,
                        color: AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ir al catálogo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.textSubtle.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No pudimos cargar tu carrito',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 2, color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Subtotal',
            '\$${_cart.total.toStringAsFixed(2)}',
            valueColor: AppColors.textDark,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Envío', 'Gratis', valueColor: AppColors.success),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${_cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
