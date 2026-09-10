import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BackIconButton extends StatelessWidget {
  final VoidCallback? onTap;

  const BackIconButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1, color: AppColors.border),
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
    );
  }
}
