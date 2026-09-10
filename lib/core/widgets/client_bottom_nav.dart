import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ClientBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const ClientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': 'Inicio',
      },
      {
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view_rounded,
        'label': 'Catálogo',
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart_rounded,
        'label': 'Carrito',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long_rounded,
        'label': 'Historial',
      },
      {
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'label': 'Perfil',
      },
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final isCart = index == 2;

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected
                              ? (items[index]['activeIcon'] as IconData)
                              : (items[index]['icon'] as IconData),
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        if (isCart && cartCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[index]['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
