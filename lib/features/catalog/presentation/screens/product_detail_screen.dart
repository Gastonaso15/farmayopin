import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/product_model.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final String? token;
  final VoidCallback? onEdit;
  final VoidCallback? onViewPurchaseHistory;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.token,
    this.onEdit,
    this.onViewPurchaseHistory,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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

    final updated = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: _product,
          token: widget.token,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _product = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStock = _product.stock > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Navegacion Superior
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_product),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1,
                          color: AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Detalle del Producto',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        border: Border.all(
                          width: 1,
                          color: AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _product.imagenUrl.isNotEmpty
                          ? Image.network(
                              _product.imagenUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          hasStock
                              ? 'Stock disponible: ${_product.stock} unidades'
                              : 'Producto sin stock disponible',
                          style: TextStyle(
                            color: hasStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
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
                        onPressed: widget.onViewPurchaseHistory ?? () => _showComingSoonSnackBar(context, 'Historial de compras proximamente (UC-08).'),
                        icon: const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
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

  void _showComingSoonSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
