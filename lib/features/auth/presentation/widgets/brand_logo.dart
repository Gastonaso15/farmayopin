import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const BrandLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(iconSize * 0.3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.local_pharmacy_rounded,
            color: Colors.white,
            size: iconSize * 0.55,
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Farma',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Y',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Opin',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
