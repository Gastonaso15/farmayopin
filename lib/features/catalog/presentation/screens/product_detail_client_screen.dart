import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../core/widgets/stepper_button.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../data/models/product_model.dart';

class ProductDetailClientScreen extends StatefulWidget {
  final ProductModel product;
  final String? token;
  final CartService? cartService;

  const ProductDetailClientScreen({
    super.key,
    required this.product,
    this.token,
    this.cartService,
  });

  @override
  State<ProductDetailClientScreen> createState() =>
      _ProductDetailClientScreenState();
}

class _ProductDetailClientScreenState extends State<ProductDetailClientScreen> {
  late final CartService _cartService;
  int _cantidad = 1;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
  }

  int get _stock => widget.product.stock;

  void _changeQuantity(int delta) {
    final nueva = _cantidad + delta;
    if (nueva < 1 || nueva > _stock) return;
    setState(() => _cantidad = nueva);
  }

  Future<void> _addToCart() async {
    if (_isAdding || _stock <= 0) return;

    setState(() => _isAdding = true);
    try {
      await _cartService.agregarItem(
        productoId: widget.product.id,
        cantidad: _cantidad,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() => _isAdding = false);
      _showSnack('${widget.product.nombre} agregado al carrito.');
    } on CartException catch (e) {
      if (!mounted) return;
      setState(() => _isAdding = false);
      _showSnack(e.message, isError: true);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Detalle del producto'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(),
                    const SizedBox(height: 20),
                    _buildInfo(),
                    const SizedBox(height: 20),
                    _buildQuantitySelector(),
                    const SizedBox(height: 20),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClientBottomNav(currentIndex: 1, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) {
    if (index == 0 || index == 1) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 220,
        color: const Color(0xFFF3F4F6),
        child: widget.product.imagenUrl.isNotEmpty
            ? Image.network(
                widget.product.imagenUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return const Center(
      child: Icon(
        Icons.medication_rounded,
        size: 64,
        color: AppColors.textSubtle,
      ),
    );
  }

  Widget _buildInfo() {
    final hasStock = _stock > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.nombre,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.product.categoria,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '\$${widget.product.precio.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hasStock
                ? 'Stock disponible: $_stock unidades'
                : 'Producto sin stock disponible',
            style: TextStyle(
              color: hasStock ? AppColors.success : AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.detalle.isNotEmpty
              ? widget.product.detalle
              : 'Sin descripción detallada disponible.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    final hasStock = _stock > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            StepperButton(
              icon: Icons.remove_rounded,
              size: 44,
              iconSize: 20,
              radius: 12,
              onTap: hasStock && _cantidad > 1
                  ? () => _changeQuantity(-1)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              '$_cantidad',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 16),
            StepperButton(
              icon: Icons.add_rounded,
              size: 44,
              iconSize: 20,
              radius: 12,
              onTap: hasStock && _cantidad < _stock
                  ? () => _changeQuantity(1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    final hasStock = _stock > 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: hasStock && !_isAdding ? _addToCart : null,
            child: _isAdding
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Agregar al carrito'),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            'Volver al catálogo',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
