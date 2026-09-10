import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../routing/app_navigator.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/catalog_service.dart';
import '../widgets/eliminar_producto_dialog.dart';

class ManageProductsScreen extends StatefulWidget {
  final String token;
  final CatalogService? catalogService;

  const ManageProductsScreen({
    super.key,
    required this.token,
    this.catalogService,
  });

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  late final CatalogService _catalogService;

  List<ProductModel> _products = [];
  bool _isLoading = true;

  static const int _umbralStockBajo = 10;

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? CatalogService();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _catalogService.getProductos(token: widget.token);
    if (!mounted) return;
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _openCreate() async {
    final created = await AppNavigator.toCreateProduct(
      context,
      token: widget.token,
    );
    if (created != null) _loadProducts();
  }

  Future<void> _openDetail(ProductModel product) async {
    await AppNavigator.toProductDetailAdmin(
      context,
      product: product,
      token: widget.token,
    );
    _loadProducts();
  }

  Future<void> _openEdit(ProductModel product) async {
    final updated = await AppNavigator.toEditProduct(
      context,
      product: product,
      token: widget.token,
    );
    if (updated != null) _loadProducts();
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await EliminarProductoDialog.show(
      context,
      nombreProducto: product.nombre,
    );

    if (confirmed != true || !mounted) return;

    try {
      await _catalogService.eliminarProducto(product.id, token: widget.token);
      if (!mounted) return;
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.nombre}" fue eliminado del catálogo.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CatalogException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Gestionar Productos'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Crear nuevo producto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
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
    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos en el catálogo.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProducts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        itemCount: _products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildProductRow(_products[index]),
      ),
    );
  }

  Widget _buildProductRow(ProductModel product) {
    final stockBajo = product.stock < _umbralStockBajo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFFFAFAFA),
              child: product.imagenUrl.isNotEmpty
                  ? Image.network(
                      product.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stockBajo ? AppColors.error : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.stock} uds',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionButton(
            icon: Icons.visibility_outlined,
            bg: const Color(0xFFF0F9FF),
            color: AppColors.link,
            onTap: () => _openDetail(product),
          ),
          const SizedBox(width: 4),
          _actionButton(
            icon: Icons.edit_outlined,
            bg: const Color(0xFFF0FDFA),
            color: AppColors.primary,
            onTap: () => _openEdit(product),
          ),
          const SizedBox(width: 4),
          _actionButton(
            icon: Icons.delete_outline_rounded,
            bg: const Color(0xFFFEE2E2),
            color: AppColors.error,
            onTap: () => _confirmDelete(product),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _imageFallback() {
    return const Center(
      child: Icon(
        Icons.medication_rounded,
        size: 26,
        color: AppColors.textSubtle,
      ),
    );
  }
}
