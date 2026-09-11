import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../routing/app_navigator.dart';
import '../../../../data/models/product_model.dart';

class ProductDetailAdminScreen extends StatefulWidget {
  final ProductModel product;
  final String? token;
  final VoidCallback? onEdit;
  final VoidCallback? onViewPurchaseHistory;

  const ProductDetailAdminScreen({
    super.key,
    required this.product,
    this.token,
    this.onEdit,
    this.onViewPurchaseHistory,
  });

  @override
  State<ProductDetailAdminScreen> createState() =>
      _ProductDetailAdminScreenState();
}

class _ProductDetailAdminScreenState extends State<ProductDetailAdminScreen> {
  late ProductModel _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _handleEditNavigation(BuildContext context) async {
    if (widget.onEdit != null) {
      widget.onEdit!();
      return;
    }

    final updated = await AppNavigator.toEditProduct(
      context,
      product: _product,
      token: widget.token,
    );

    if (updated != null && mounted) {
      setState(() {
        _product = updated;
      });
    }
  }

  Future<void> _handleHistorialNavigation(BuildContext context) async {
    if (widget.onViewPurchaseHistory != null) {
      widget.onViewPurchaseHistory!();
      return;
    }

    await AppNavigator.toHistorialProducto(
      context,
      product: _product,
      token: widget.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStock = _product.stock > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Detalle del Producto',
              onBack: () => Navigator.of(context).pop(_product),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del Producto
                    Container(
                      width: double.infinity,
                      height: 220,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(width: 1, color: AppColors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _product.imagenUrl.isNotEmpty
                          ? Image.network(
                              _product.imagenUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    const SizedBox(height: 20),

                    // Titulo y Categoria
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product.nombre,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border.all(
                              width: 1,
                              color: AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _product.categoria,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Precio
                    Text(
                      '\$${_product.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badge de Stock
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          hasStock
                              ? 'Stock disponible: ${_product.stock} unidades'
                              : 'Producto sin stock disponible',
                          style: TextStyle(
                            color: hasStock
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descripcion / Detalle
                    Text(
                      _product.detalle.isNotEmpty
                          ? _product.detalle
                          : 'Sin descripcion detallada disponible.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botones de Accion
                    // 1. Boton Editar Producto (Primario)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleEditNavigation(context),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Editar producto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Boton Ver historial de compras (Outlined)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleHistorialNavigation(context),
                        icon: const Icon(
                          Icons.history_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Ver historial de compras',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            width: 2,
                            color: AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.medication_rounded,
          size: 64,
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}
