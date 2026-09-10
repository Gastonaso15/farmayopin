import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// Pantalla de carga (splash) mostrada al iniciar la app, adaptada del
/// diseño de Figma "Pantalladecarga". Muestra la marca brevemente y luego
/// navega al login: la app no persiste sesión entre lanzamientos, así que
/// no hay nada que "verificar" aquí, solo una presentación de marca.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              _buildLogo(),
              const SizedBox(height: 24),
              _buildBrand(),
              const Spacer(flex: 4),
              const Text(
                'GRUPO FARMACÉUTICO NACIONAL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: const ShapeDecoration(
        color: Color(0xFFF0F9FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(70)),
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: ShapeDecoration(
            color: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
            shadows: const [
              BoxShadow(
                color: AppColors.primaryShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_pharmacy_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Farma',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Y',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Opin',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu farmacia, siempre contigo',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
