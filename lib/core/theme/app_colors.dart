import 'package:flutter/material.dart';

/// Paleta de colores de FarmaYopin extraída del diseño de Figma.
class AppColors {
  AppColors._();

  // Colores principales de la marca
  static const Color primary = Color(0xFF0D9488); // Teal principal
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryShadow = Color(0x330D9488);

  // Colores de texto y neutros oscuros
  static const Color textDark = Color(0xFF1F2937); // Texto principal / títulos
  static const Color textMuted = Color(0xFF6B7280); // Subtítulos y placeholders
  static const Color textSubtle = Color(0xFF9CA3AF);

  // Bordes y superficies
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF0D9488);
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF9FAFB);

  // Acentos y estados
  static const Color link = Color(0xFF0284C7); // "¿Olvidaste tu contraseña?"
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
}
