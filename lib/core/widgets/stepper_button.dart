import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double radius;

  const StepperButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.iconSize = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap == null ? AppColors.textSubtle : AppColors.textDark,
        ),
      ),
    );
  }
}
