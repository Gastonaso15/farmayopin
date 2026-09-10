import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../data/models/cart_model.dart';
import '../../../../data/services/cart_service.dart';

class ConfirmPurchaseScreen extends StatefulWidget {
  final CartModel cart;
  final String? token;
  final CartService? cartService;

  const ConfirmPurchaseScreen({
    super.key,
    required this.cart,
    this.token,
    this.cartService,
  });

  @override
  State<ConfirmPurchaseScreen> createState() => _ConfirmPurchaseScreenState();
}

class _ConfirmPurchaseScreenState extends State<ConfirmPurchaseScreen> {
  late final CartService _cartService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
  }

  Future<void> _confirmarPago() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final compra = await _cartService.pagarCarrito(token: widget.token);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      await _showPaymentSuccess(compra);
      if (mounted) Navigator.of(context).pop(true);
    } on CartException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnack(e.message, isError: true);
    }
  }

  Future<void> _showPaymentSuccess(Map<String, dynamic> compra) {
    final total = (compra['total'] as num?)?.toDouble();
    final compraId = compra['id'];

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Compra realizada con éxito',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (compraId != null) 'Pedido #$compraId',
                if (total != null)
                  'Total pagado: \$${total.toStringAsFixed(2)}',
              ].join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al catálogo'),
            ),
          ),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Confirmar Compra',
              onBack: () => Navigator.of(context).pop(false),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Resumen de tu pedido'),
                    const SizedBox(height: 16),
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Método de pago'),
                    const SizedBox(height: 10),
                    _buildPaymentMethod(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Dirección de entrega'),
                    const SizedBox(height: 10),
                    _buildDeliveryAddress(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _confirmarPago,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmar pago'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 2,
        cartCount: widget.cart.cantidadUnidades,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0 || index == 1 || index == 2) {
      Navigator.of(context).pop(false);
    }
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in widget.cart.items) ...[
            _buildSummaryRow(item),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a pagar',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${widget.cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(CartItemModel item) {
    return Row(
      children: [
        Text(
          'x${item.cantidad}',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.nombreProducto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.credit_card_rounded,
            size: 24,
            color: AppColors.textDark,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarjeta de Crédito',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Visa terminada en 4532',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            'Cambiar',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            size: 22,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Casa (Sofía)',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Av. de la Constitución 142, Piso 4B',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
