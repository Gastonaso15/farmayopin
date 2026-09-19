import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/local/compra_local_database.dart';
import '../../../../data/models/auth_response.dart';
import '../../../../data/models/login_request.dart';
import '../../../../data/models/user_session_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/compra_service.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../routing/app_navigator.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final CompraLocalDatabase? localDatabase;
  final CompraService? compraService;

  const LoginScreen({
    super.key,
    this.authService,
    this.localDatabase,
    this.compraService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  late final CompraLocalDatabase _localDb;
  late final CompraService _compraService;

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _hasOfflineData = false;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _localDb = widget.localDatabase ?? CompraLocalDatabase();
    _compraService = widget.compraService ?? CompraService(localDatabase: _localDb);
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      final session = await _localDb.getActiveSession();
      if (session != null && mounted) {
        setState(() {
          _rememberMe = session.rememberMe;
          _savedEmail = session.email;
          _hasOfflineData = true;
          if (_emailController.text.isEmpty) {
            _emailController.text = session.email;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Cerrar teclado
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final AuthResponse response = await _authService.login(request);

      // 1. Sincronizar automáticamente el historial de compras local cada vez que se inicia sesión
      if (response.rol == UserRole.cliente) {
        try {
          await _compraService.syncHistorialConServidor(
            token: response.token,
            userEmail: response.email,
          );
        } catch (_) {
          // No interrumpir el flujo del usuario si la sincronización inmediata falla
        }
      }

      // 2. Persistir o limpiar sesión según la opción 'Mantener sesión iniciada'
      try {
        if (_rememberMe) {
          final userSession = UserSessionModel(
            email: response.email,
            nombre: response.nombre,
            token: response.token,
            rol: response.rol,
            rememberMe: true,
            isActive: true,
            lastLogin: DateTime.now(),
          );
          await _localDb.saveSession(userSession, plainPassword: password);
        } else {
          await _localDb.clearActiveSession();
        }
      } catch (dbError) {
        debugPrint('Advertencia: no se pudo persistir la sesión local: $dbError');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Bienvenido, ${response.nombre.isNotEmpty ? response.nombre : response.email}! (${response.rol.toDisplayString()})',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppNavigator.toHomeForRole(context, response);
    } catch (e) {
      if (!mounted) return;

      // Detectar fallo por falta de conexión al servidor y habilitar login local
      final isNetworkError = e is AuthException &&
          (e.message.contains('No se pudo conectar') ||
              e.message.contains('Error de comunicación') ||
              e.message.contains('SocketException'));

      if (isNetworkError) {
        final isValidLocal =
            await _localDb.validateLocalCredentials(email, password);

        if (isValidLocal) {
          final session = await _localDb.getSessionByEmail(email);
          if (session != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sin conexión con el servidor. Accediendo al historial de compras en modo local.',
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            AppNavigator.toOfflineHistorial(
              context,
              userEmail: session.email,
              compraService: _compraService,
            );
            return;
          }
        } else {
          // Intentar verificar si al menos hay compras guardadas de ese email
          final localCompras = await _localDb.getComprasByUser(email);
          if (localCompras.isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sin conexión con el servidor. No hay datos ni credenciales guardadas localmente para este usuario.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDirectOfflineAccess() async {
    if (_savedEmail == null) return;
    AppNavigator.toOfflineHistorial(
      context,
      userEmail: _savedEmail!,
      compraService: _compraService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo de marca
                    const BrandLogo(),
                    const SizedBox(height: 28),

                    // Título y bienvenida
                    const Text(
                      '¡Hola de nuevo!',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Inicia sesión para gestionar tus pedidos y recetas médicas.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo de Correo Electrónico
                    CustomTextField(
                      label: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Campo de Contraseña
                    CustomTextField(
                      label: 'Contraseña',
                      hintText: '••••••••••••',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _isPasswordObscured,
                      textInputAction: TextInputAction.done,
                      validator: Validators.validatePassword,
                      onFieldSubmitted: (_) => _handleLogin(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fila: Mantener sesión iniciada & Olvidé mi contraseña
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Mantener sesión iniciada',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recuperación de contraseña próximamente.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppColors.link,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón de Iniciar Sesión
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.primaryShadow,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    // Botón de acceso sin conexión si hay sesión/datos previos
                    if (_hasOfflineData && _savedEmail != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleDirectOfflineAccess,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Ver historial sin conexión ($_savedEmail)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Link de Registro
                    Center(
                      child: GestureDetector(
                        onTap: () => AppNavigator.toRegister(context),
                        child: Text.rich(
                          TextSpan(
                            children: const [
                              TextSpan(
                                text: '¿No tienes una cuenta? ',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: 'Regístrate',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
