import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/compra_local_database.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/compra_service.dart';
import '../../../../routing/app_navigator.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// Pantalla de carga (splash) mostrada al iniciar la app.
/// Verifica si existe una sesión guardada activa ('Mantener sesión iniciada').
/// - Si hay sesión y conexión: ingresa al Home correspondiente y sincroniza compras.
/// - Si hay sesión pero no hay conexión: ingresa al modo local offline (Historial).
/// - Si no hay sesión: navega a la pantalla de Login.
class SplashScreen extends StatefulWidget {
  final CompraLocalDatabase? localDatabase;
  final AuthService? authService;
  final CompraService? compraService;

  const SplashScreen({
    super.key,
    this.localDatabase,
    this.authService,
    this.compraService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final CompraLocalDatabase _localDb;
  late final AuthService _authService;
  late final CompraService _compraService;

  @override
  void initState() {
    super.initState();
    _localDb = widget.localDatabase ?? CompraLocalDatabase();
    _authService = widget.authService ?? AuthService();
    _compraService =
        widget.compraService ?? CompraService(localDatabase: _localDb);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Espera mínima para mostrar la identidad de marca
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    try {
      final session = await _localDb.getActiveSession();

      if (session != null) {
        final isOnline = await _authService.checkServerConnection(
          timeout: const Duration(milliseconds: 1800),
        );

        if (!mounted) return;

        if (isOnline) {
          // Sincronizar en segundo plano compras de cliente
          _compraService.syncHistorialConServidor(
            token: session.token,
            userEmail: session.email,
          );
          AppNavigator.toHomeForRole(context, session.toAuthResponse());
          return;
        } else {
          // Iniciar en modo offline para consulta local del historial de compras
          AppNavigator.toOfflineHistorial(context, userEmail: session.email);
          return;
        }
      }
    } catch (_) {
      // En caso de cualquier error, proceder al login habitual
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          localDatabase: _localDb,
          authService: _authService,
          compraService: _compraService,
        ),
      ),
    );
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
