import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/models/compra_item_model.dart';
import '../../../../data/models/compra_model.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../routing/app_navigator.dart';

/// Pantalla de detalle de una compra, adaptada del diseño de Figma
/// "Detallecompra" a datos reales de GET /api/compras.
///
/// El diseño original incluía una insignia de estado ("En proceso") y un
/// costo de envío; ninguno de los dos existe en el backend (Compra no tiene
/// campo de estado ni de envío), así que se omite la insignia y el envío se
/// muestra como "Gratis" porque, en efecto, este sistema no cobra envío.
class DetalleCompraScreen extends StatefulWidget {
  final CompraModel compra;
  final String? token;
  final CartService? cartService;

  const DetalleCompraScreen({
    super.key,
    required this.compra,
    this.token,
    this.cartService,
  });

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  late final CartService _cartService;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (mounted) setState(() => _cartItemCount = cart.cantidadUnidades);
    } on CartException catch (_) {}
  }

  Future<void> _onNavTap(int index) async {
    if (index == 3) return; // ya estamos en Historial
    if (index == 2) {
      await AppNavigator.toCart(context, token: widget.token);
      _refreshCartCount();
      return;
    }
    Navigator.of(context).pop();
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final esHoy =
        fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    if (esHoy) {
      return 'Realizado el Hoy, $hora:${minuto}h';
    }
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return 'Realizado el $dia/$mes/${fecha.year}, $hora:${minuto}h';
  }

  @override
  Widget build(BuildContext context) {
    final compra = widget.compra;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Detalle de Compra',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderInfo(compra),
                    const SizedBox(height: 20),
                    const Text(
                      'Productos',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in compra.items) ...[
                      _buildItemRow(item),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    _buildSummary(compra),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 3,
        cartCount: _cartItemCount,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildOrderInfo(CompraModel compra) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedido #${compra.id}',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatFecha(compra.fecha),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(CompraItemModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 24,
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${item.precioUnitario.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cant: ${item.cantidad}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CompraModel compra) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Subtotal', '\$${compra.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildSummaryRow('Envío', 'Gratis', valueColor: AppColors.success),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Total',
            '\$${compra.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textDark : AppColors.textMuted,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isTotal ? AppColors.primary : AppColors.textDark),
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
