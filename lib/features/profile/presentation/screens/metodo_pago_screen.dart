import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../data/models/tarjeta_model.dart';
import '../../../../data/services/tarjeta_service.dart';

export '../../../../data/models/tarjeta_model.dart';

enum TipoMetodoPago { tarjetaCredito, tarjetaDebito, mercadoPago, efectivo }

class MetodoPagoModel {
  final String id;
  final String titulo;
  final String subtitulo;
  final String ultimosCuatro;
  final String titular;
  final String vencimiento;
  final TipoMetodoPago tipo;
  final bool isDefault;

  MetodoPagoModel({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    this.ultimosCuatro = '',
    this.titular = '',
    this.vencimiento = '',
    required this.tipo,
    this.isDefault = false,
  });

  MetodoPagoModel copyWith({bool? isDefault}) {
    return MetodoPagoModel(
      id: id,
      titulo: titulo,
      subtitulo: subtitulo,
      ultimosCuatro: ultimosCuatro,
      titular: titular,
      vencimiento: vencimiento,
      tipo: tipo,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Pantalla "Método de pago" para consultar, seleccionar y
/// gestionar tarjetas y métodos de pago del usuario en FarmaYopin.
class MetodoPagoScreen extends StatefulWidget {
  final String? token;
  final TarjetaService? tarjetaService;

  const MetodoPagoScreen({
    super.key,
    this.token,
    this.tarjetaService,
  });

  @override
  State<MetodoPagoScreen> createState() => _MetodoPagoScreenState();
}

class _MetodoPagoScreenState extends State<MetodoPagoScreen> {
  late final TarjetaService _tarjetaService;
  bool _isLoading = false;

  final List<MetodoPagoModel> _fallbackMetodos = [
    MetodoPagoModel(
      id: '1',
      titulo: 'Visa Crédito',
      subtitulo: 'Terminada en 4532',
      ultimosCuatro: '4532',
      titular: 'GASTON PEREZ',
      vencimiento: '08/29',
      tipo: TipoMetodoPago.tarjetaCredito,
      isDefault: true,
    ),
    MetodoPagoModel(
      id: '2',
      titulo: 'Mastercard Débito',
      subtitulo: 'Terminada en 8819',
      ultimosCuatro: '8819',
      titular: 'GASTON PEREZ',
      vencimiento: '11/27',
      tipo: TipoMetodoPago.tarjetaDebito,
      isDefault: false,
    ),
    MetodoPagoModel(
      id: '3',
      titulo: 'Mercado Pago',
      subtitulo: 'Cuenta vinculada: gastonaso16@gmail.com',
      tipo: TipoMetodoPago.mercadoPago,
      isDefault: false,
    ),
    MetodoPagoModel(
      id: '4',
      titulo: 'Efectivo contra entrega',
      subtitulo: 'Pagas al recibir tu pedido en domicilio',
      tipo: TipoMetodoPago.efectivo,
      isDefault: false,
    ),
  ];

  List<MetodoPagoModel> _metodos = [];

  @override
  void initState() {
    super.initState();
    _tarjetaService = widget.tarjetaService ?? TarjetaService();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _cargarTarjetas();
    } else {
      _metodos = List.from(_fallbackMetodos);
    }
  }

  Future<void> _cargarTarjetas() async {
    setState(() => _isLoading = true);

    try {
      final serverCards = await _tarjetaService.getTarjetas(token: widget.token);
      if (!mounted) return;

      final List<MetodoPagoModel> combinados = serverCards.map((t) {
        return MetodoPagoModel(
          id: t.id,
          titulo: t.titulo,
          subtitulo: t.subtitulo,
          ultimosCuatro: t.ultimosCuatro,
          titular: t.titular,
          vencimiento: t.vencimiento,
          tipo: t.tipo == 'DEBITO'
              ? TipoMetodoPago.tarjetaDebito
              : TipoMetodoPago.tarjetaCredito,
          isDefault: t.isDefault,
        );
      }).toList();

      // Añadir los métodos complementarios no-tarjeta (Mercado Pago y Efectivo)
      combinados.add(
        MetodoPagoModel(
          id: 'mp',
          titulo: 'Mercado Pago',
          subtitulo: 'Cuenta vinculada a billetera virtual',
          tipo: TipoMetodoPago.mercadoPago,
          isDefault: false,
        ),
      );
      combinados.add(
        MetodoPagoModel(
          id: 'ef',
          titulo: 'Efectivo contra entrega',
          subtitulo: 'Pagas al recibir tu pedido en domicilio',
          tipo: TipoMetodoPago.efectivo,
          isDefault: false,
        ),
      );

      setState(() {
        _metodos = combinados.isNotEmpty ? combinados : List.from(_fallbackMetodos);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_metodos.isEmpty) {
          _metodos = List.from(_fallbackMetodos);
        }
        _isLoading = false;
      });
    }
  }

  MetodoPagoModel get _tarjetaSeleccionada {
    return _metodos.firstWhere(
      (m) =>
          m.isDefault &&
          (m.tipo == TipoMetodoPago.tarjetaCredito ||
              m.tipo == TipoMetodoPago.tarjetaDebito),
      orElse: () => _metodos.firstWhere(
        (m) =>
            m.tipo == TipoMetodoPago.tarjetaCredito ||
            m.tipo == TipoMetodoPago.tarjetaDebito,
        orElse: () => _metodos.first,
      ),
    );
  }

  Future<void> _establecerPredeterminado(String id) async {
    setState(() {
      for (int i = 0; i < _metodos.length; i++) {
        _metodos[i] = _metodos[i].copyWith(isDefault: _metodos[i].id == id);
      }
    });

    if (widget.token != null && widget.token!.isNotEmpty && id != 'mp' && id != 'ef') {
      try {
        await _tarjetaService.marcarComoPrincipal(id: id, token: widget.token);
      } catch (e) {
        debugPrint('Aviso: no se pudo marcar tarjeta principal en el servidor: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Método de pago predeterminado actualizado.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _eliminarMetodo(String id) async {
    final metodo = _metodos.firstWhere((m) => m.id == id);
    if (metodo.isDefault && _metodos.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige otro método predeterminado antes de eliminar este.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _metodos.removeWhere((m) => m.id == id);
    });

    if (widget.token != null && widget.token!.isNotEmpty && id != 'mp' && id != 'ef') {
      try {
        await _tarjetaService.eliminarTarjeta(id: id, token: widget.token);
      } catch (e) {
        debugPrint('Aviso: no se pudo eliminar tarjeta del servidor: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Método de pago eliminado.'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarModalNuevaTarjeta() {
    final numeroController = TextEditingController();
    final titularController = TextEditingController();
    final vencimientoController = TextEditingController();
    final cvvController = TextEditingController();
    bool setAsDefault = true;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Agregar Tarjeta de Crédito / Débito',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Transacciones 100% protegidas y encriptadas con SSL.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: numeroController,
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                          hintText: '4532 •••• •••• ••••',
                          prefixIcon: Icon(Icons.credit_card_rounded),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 15) {
                            return 'Ingresa un número de tarjeta válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titularController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Nombre y apellido del titular',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: vencimientoController,
                              keyboardType: TextInputType.datetime,
                              maxLength: 5,
                              decoration: const InputDecoration(
                                labelText: 'Vencimiento (MM/AA)',
                                hintText: '08/29',
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v == null || !v.contains('/')) {
                                  return 'Inválido (MM/AA)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                labelText: 'CVV / Código',
                                hintText: '•••',
                                counterText: '',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 3) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: setAsDefault,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() => setAsDefault = val ?? false);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Usar como método de pago principal',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final numLimpio = numeroController.text.replaceAll(
                                ' ',
                                '',
                              );
                              final ultimos = numLimpio.length >= 4
                                  ? numLimpio.substring(numLimpio.length - 4)
                                  : '0000';

                              final esVisa = numLimpio.startsWith('4');
                              final nuevo = MetodoPagoModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                titulo: esVisa
                                    ? 'Visa Crédito'
                                    : 'Mastercard Crédito',
                                subtitulo: 'Terminada en $ultimos',
                                ultimosCuatro: ultimos,
                                titular: titularController.text
                                    .trim()
                                    .toUpperCase(),
                                vencimiento: vencimientoController.text.trim(),
                                tipo: TipoMetodoPago.tarjetaCredito,
                                isDefault: setAsDefault,
                              );

                              if (widget.token != null &&
                                  widget.token!.isNotEmpty) {
                                _tarjetaService
                                    .crearTarjeta(
                                  tarjeta: TarjetaModel(
                                    id: '',
                                    marca: esVisa ? 'Visa' : 'Mastercard',
                                    tipo: 'CREDITO',
                                    ultimosCuatro: ultimos,
                                    titular: titularController.text
                                        .trim()
                                        .toUpperCase(),
                                    vencimiento:
                                        vencimientoController.text.trim(),
                                    isDefault: setAsDefault,
                                  ),
                                  token: widget.token,
                                )
                                    .then((_) {
                                  if (mounted) _cargarTarjetas();
                                }).catchError((e) {
                                  debugPrint(
                                      'Aviso: no se pudo sincronizar tarjeta con el backend: $e');
                                });
                              }

                              setState(() {
                                if (setAsDefault) {
                                  for (int i = 0; i < _metodos.length; i++) {
                                    _metodos[i] = _metodos[i]
                                        .copyWith(isDefault: false);
                                  }
                                }
                                _metodos.insert(0, nuevo);
                              });

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tarjeta guardada con éxito.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar tarjeta'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Método de pago',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVirtualCard(_tarjetaSeleccionada),
                          const SizedBox(height: 20),
                          const Text(
                            'Tus métodos de pago',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._metodos.map((m) => _buildPaymentItem(m)),
                          const SizedBox(height: 16),
                          _buildSecurityNote(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualCard(MetodoPagoModel tarjeta) {
    final hasDetails = tarjeta.ultimosCuatro.isNotEmpty;
    final titular = hasDetails ? tarjeta.titular : 'CLIENTE FARMAYOPIN';
    final ultimos = hasDetails ? tarjeta.ultimosCuatro : '4532';
    final vencimiento = hasDetails ? tarjeta.vencimiento : '08/29';

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x350F766E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'FarmaYOpin Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.contactless_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
          // Chip EMV
          Row(
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD34D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD97706),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Número de tarjeta
          Text(
            '••••  ••••  ••••  $ultimos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titular,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VENCE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vencimiento,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(MetodoPagoModel m) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (m.tipo) {
      case TipoMetodoPago.tarjetaCredito:
      case TipoMetodoPago.tarjetaDebito:
        icon = Icons.credit_card_rounded;
        iconBg = const Color(0xFFE6FFFA);
        iconColor = AppColors.primary;
        break;
      case TipoMetodoPago.mercadoPago:
        icon = Icons.account_balance_wallet_rounded;
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        break;
      case TipoMetodoPago.efectivo:
        icon = Icons.payments_outlined;
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isDefault ? AppColors.primary : AppColors.border,
          width: m.isDefault ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.titulo,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (m.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FFFA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Predeterminada',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  m.subtitulo,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            onSelected: (val) {
              if (val == 'default') {
                _establecerPredeterminado(m.id);
              } else if (val == 'delete') {
                _eliminarMetodo(m.id);
              }
            },
            itemBuilder: (context) => [
              if (!m.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Establecer como principal'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Eliminar método',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 18, color: Color(0xFF16A34A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tus pagos están protegidos. No almacenamos tu código de seguridad (CVV). Toda la información se procesa bajo el estándar PCI-DSS.',
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _mostrarModalNuevaTarjeta,
          icon: const Icon(Icons.add_card_rounded, size: 20),
          label: const Text(
            'Agregar tarjeta o método de pago',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
