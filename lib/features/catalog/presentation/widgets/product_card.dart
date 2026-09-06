import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStock = product.stock > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: const [
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
          // Imagen del producto con fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 100,
              color: const Color(0xFFF3F4F6),
              child: Image.network(
                product.foto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.medication_rounded,
                      size: 40,
                      color: AppColors.textSubtle,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Título del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Precio
                Text(
                  '\$${product.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),

                // Indicador de Stock
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasStock ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasStock ? 'Stock: ${product.stock} disp.' : 'Sin stock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Botón Agregar al carrito
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: hasStock ? onAddToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Agregar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
