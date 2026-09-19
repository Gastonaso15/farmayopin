import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../data/models/direccion_model.dart';
import '../../../../data/services/direccion_service.dart';

export '../../../../data/models/direccion_model.dart';

/// Pantalla "Dirección de entrega" para consultar, seleccionar y
/// gestionar las direcciones de envío del usuario en FarmaYopin.
class DireccionEntregaScreen extends StatefulWidget {
  final String? token;
  final DireccionService? direccionService;

  const DireccionEntregaScreen({
    super.key,
    this.token,
    this.direccionService,
  });

  @override
  State<DireccionEntregaScreen> createState() => _DireccionEntregaScreenState();
}

class _DireccionEntregaScreenState extends State<DireccionEntregaScreen> {
  late final DireccionService _direccionService;
  List<DireccionModel> _direcciones = [];
  bool _isLoading = false;

  final List<DireccionModel> _fallbackDirecciones = [
    DireccionModel(
      id: '1',
      alias: 'Casa (Principal)',
      calle: 'Calle 25 de Mayo',
      numero: '742',
      pisoDepto: 'Apto 302',
      ciudad: 'Maldonado',
      codigoPostal: '20000',
      notas: 'Timbre 302. Dejar en recepción si no respondo.',
      isDefault: true,
      icon: Icons.home_rounded,
    ),
    DireccionModel(
      id: '2',
      alias: 'Trabajo / Oficina',
      calle: 'Av. Roosevelt y Parada 8',
      numero: 'Torre del Sol',
      pisoDepto: 'Piso 4, Of. 402',
      ciudad: 'Punta del Este, Maldonado',
      codigoPostal: '20100',
      notas: 'Horario comercial 9:00 a 18:00 hs.',
      isDefault: false,
      icon: Icons.business_rounded,
    ),
    DireccionModel(
      id: '3',
      alias: 'Casa de mis Padres',
      calle: 'Calle 18 de Julio',
      numero: '450',
      pisoDepto: '',
      ciudad: 'San Carlos, Maldonado',
      codigoPostal: '20400',
      notas: 'Portón blanco de rejas.',
      isDefault: false,
      icon: Icons.holiday_village_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _direccionService = widget.direccionService ?? DireccionService();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _cargarDirecciones();
    } else {
      _direcciones = List.from(_fallbackDirecciones);
    }
  }

  Future<void> _cargarDirecciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _direccionService.getDirecciones(token: widget.token);
      if (!mounted) return;
      setState(() {
        _direcciones = list.isNotEmpty ? list : List.from(_fallbackDirecciones);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // En caso de error de red inicial, preservar datos de muestra para no bloquear la pantalla
        if (_direcciones.isEmpty) {
          _direcciones = List.from(_fallbackDirecciones);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _establecerPredeterminada(String id) async {
    // Actualización optimista en UI
    setState(() {
      for (int i = 0; i < _direcciones.length; i++) {
        _direcciones[i] =
            _direcciones[i].copyWith(isDefault: _direcciones[i].id == id);
      }
    });

    if (widget.token != null && widget.token!.isNotEmpty) {
      try {
        await _direccionService.marcarComoPrincipal(id: id, token: widget.token);
      } catch (e) {
        debugPrint('Aviso: no se pudo sincronizar dirección principal en el servidor: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dirección predeterminada actualizada.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _eliminarDireccion(String id) async {
    final direccion = _direcciones.firstWhere((d) => d.id == id);
    if (direccion.isDefault && _direcciones.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige otra dirección predeterminada antes de eliminar esta.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _direcciones.removeWhere((d) => d.id == id);
    });

    if (widget.token != null && widget.token!.isNotEmpty) {
      try {
        await _direccionService.eliminarDireccion(id: id, token: widget.token);
      } catch (e) {
        debugPrint('Aviso: no se pudo eliminar dirección del servidor: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dirección eliminada.'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarModalAgregarDireccion() {
    final aliasController = TextEditingController();
    final calleController = TextEditingController();
    final numeroController = TextEditingController();
    final pisoController = TextEditingController();
    final ciudadController = TextEditingController(text: 'Maldonado');
    final cpController = TextEditingController(text: '20000');
    final notasController = TextEditingController();
    bool setAsDefault = _direcciones.isEmpty;
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
                        'Nueva Dirección de Entrega',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Indica dónde recibirás tus medicamentos y pedidos.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: aliasController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre / Alias (ej. Casa, Trabajo)',
                          prefixIcon: Icon(Icons.bookmark_border_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: calleController,
                              decoration: const InputDecoration(
                                labelText: 'Calle',
                                prefixIcon: Icon(Icons.edit_road_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: numeroController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Número',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pisoController,
                              decoration: const InputDecoration(
                                labelText: 'Piso / Depto (opcional)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: cpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Código Postal',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ciudadController,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad / Localidad',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notasController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Indicaciones para el repartidor',
                          hintText: 'Color del portón, timbre, etc.',
                        ),
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
                              'Establecer como dirección predeterminada',
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
                              final nueva = DireccionModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                alias: aliasController.text.trim(),
                                calle: calleController.text.trim(),
                                numero: numeroController.text.trim(),
                                pisoDepto: pisoController.text.trim(),
                                ciudad: ciudadController.text.trim(),
                                codigoPostal: cpController.text.trim(),
                                notas: notasController.text.trim(),
                                isDefault: setAsDefault,
                              );

                              if (widget.token != null &&
                                  widget.token!.isNotEmpty) {
                                _direccionService
                                    .crearDireccion(
                                  direccion: nueva,
                                  token: widget.token,
                                )
                                    .then((_) {
                                  if (mounted) _cargarDirecciones();
                                }).catchError((e) {
                                  debugPrint(
                                      'Aviso: no se pudo sincronizar en backend: $e');
                                });
                              }

                              setState(() {
                                if (setAsDefault) {
                                  for (int i = 0;
                                      i < _direcciones.length;
                                      i++) {
                                    _direcciones[i] = _direcciones[i]
                                        .copyWith(isDefault: false);
                                  }
                                }
                                _direcciones.add(nueva);
                              });

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nueva dirección agregada con éxito.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar dirección'),
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
              title: 'Dirección de entrega',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _direcciones.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _direcciones.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final direccion = _direcciones[index];
                        return _buildDireccionCard(direccion);
                      },
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDireccionCard(DireccionModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: d.isDefault ? AppColors.primary : AppColors.border,
          width: d.isDefault ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: d.isDefault
                      ? const Color(0xFFE6FFFA)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  d.icon,
                  size: 20,
                  color: d.isDefault ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.alias,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (d.isDefault) ...[
                      const SizedBox(height: 2),
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
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onSelected: (val) {
                  if (val == 'default') {
                    _establecerPredeterminada(d.id);
                  } else if (val == 'delete') {
                    _eliminarDireccion(d.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!d.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Marcar como predeterminada'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Eliminar dirección',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            '${d.calle} ${d.numero}${d.pisoDepto.isNotEmpty ? ', ${d.pisoDepto}' : ''}',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${d.ciudad} (CP ${d.codigoPostal})',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (d.notas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSubtle,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.notas,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!d.isDefault) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _establecerPredeterminada(d.id),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Usar como dirección principal',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 64,
            color: AppColors.textSubtle.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aún no tienes direcciones guardadas',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega una dirección para recibir tus pedidos.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
          onPressed: _mostrarModalAgregarDireccion,
          icon: const Icon(Icons.add_location_alt_rounded, size: 20),
          label: const Text(
            'Agregar nueva dirección',
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
