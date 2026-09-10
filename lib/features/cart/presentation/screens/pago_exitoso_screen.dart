import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/models/compra_model.dart';
import '../../../../routing/app_navigator.dart';

/// Pantalla de confirmación de pago exitoso, adaptada del diseño de Figma
/// "Pagoexitoso" a los datos reales de la compra recién creada.
class PagoExitosoScreen extends StatelessWidget {
  final CompraModel compra;
  final String? token;

  const PagoExitosoScreen({super.key, required this.compra, this.token});

  int get _cantidadItems =>
      compra.items.fold(0, (sum, item) => sum + item.cantidad);

  void _volverAlInicio(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _verHistorial(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await AppNavigator.toHistorial(context, token: token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              _buildCheckIcon(),
              const SizedBox(height: 32),
              _buildMensaje(),
              const SizedBox(height: 32),
              _buildResumen(),
              const SizedBox(height: 32),
              _buildAcciones(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 2,
        cartCount: 0,
        onTap: (_) => _volverAlInicio(context),
      ),
    );
  }

  Widget _buildCheckIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFDCFCE7),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 40,
        color: AppColors.success,
      ),
    );
  }

  Widget _buildMensaje() {
    return Column(
      children: [
        const Text(
          'Compra realizada con éxito',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '¡Gracias por tu compra!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: const Color(0xFFF0F9FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '#${compra.id}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    final cantidad = _cantidadItems;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de compra',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _buildFila(
            'Productos ($cantidad ${cantidad == 1 ? 'item' : 'items'})',
            '\$${compra.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildFila('Envío', 'Gratis', valueColor: AppColors.success),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _buildFila(
            'Total pagado',
            '\$${compra.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFila(
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
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ?? (isTotal ? AppColors.primary : AppColors.textDark),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAcciones(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _verHistorial(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Ver historial de compras',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => _volverAlInicio(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(width: 1.5, color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Volver al inicio',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
