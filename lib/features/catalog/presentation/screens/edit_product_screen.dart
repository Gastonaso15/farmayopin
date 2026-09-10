import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/producto_request.dart';
import '../../../../data/services/catalog_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  final CatalogService? catalogService;
  final String? token;
  final ImagePicker? imagePicker;

  const EditProductScreen({
    super.key,
    required this.product,
    this.catalogService,
    this.token,
    this.imagePicker,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _stockController;

  late final CatalogService _catalogService;
  late final ImagePicker _picker;

  String? _photoUrl;
  Uint8List? _localImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? CatalogService();
    _picker = widget.imagePicker ?? ImagePicker();

    _nombreController = TextEditingController(text: widget.product.nombre);
    _descripcionController = TextEditingController(
      text: widget.product.detalle,
    );
    _precioController = TextEditingController(
      text: widget.product.precio.toStringAsFixed(2),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _photoUrl = widget.product.foto.isNotEmpty ? widget.product.foto : null;

    // Si la foto existente ya es data URI base64, decodificar los bytes
    if (_photoUrl != null && _photoUrl!.startsWith('data:image')) {
      try {
        final commaIndex = _photoUrl!.indexOf(',');
        if (commaIndex != -1) {
          _localImageBytes = base64Decode(_photoUrl!.substring(commaIndex + 1));
        }
      } catch (_) {
        // En caso de formato no válido, continúa como URL
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromStorage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';

        setState(() {
          _localImageBytes = bytes;
          _photoUrl = 'data:$mimeType;base64,$base64String';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen cargada desde el almacenamiento interno.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la imagen: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar imagen del producto',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Almacenamiento interno / Galería',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Elige una foto guardada en tu dispositivo',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImageFromStorage();
                  },
                ),
                const Divider(height: 20, color: AppColors.border),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Ingresar enlace URL web',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Pegar URL de imagen desde internet',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showPhotoUrlDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhotoUrlDialog() {
    final urlController = TextEditingController(
      text: (_photoUrl != null && !_photoUrl!.startsWith('data:'))
          ? _photoUrl!
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'URL de foto del producto',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'https://ejemplo.com/producto.jpg',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text(
                      'Medicamento',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      urlController.text = 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300&q=80';
                    },
                  ),
                  ActionChip(
                    label: const Text(
                      'Vitamina',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      urlController.text = 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=300&q=80';
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _localImageBytes = null;
                  _photoUrl = urlController.text.trim().isNotEmpty
                      ? urlController.text.trim()
                      : null;
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpdateProduct() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final precio = double.parse(
        _precioController.text.trim().replaceAll(',', '.'),
      );
      final stock = int.parse(_stockController.text.trim());

      final request = ProductoRequest(
        nombre: _nombreController.text.trim(),
        precio: precio,
        detalle: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        foto: _photoUrl,
        stock: stock,
      );

      final updated = await _catalogService.actualizarProducto(
        widget.product.id,
        request,
        token: widget.token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Producto "${updated.nombre}" actualizado exitosamente.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(updated);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Editar Producto'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Area de Foto del Producto
                          GestureDetector(
                            onTap: _showImageSourceSelector,
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: _buildImageContent(),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Botón auxiliar para cargar desde almacenamiento interno
                          Center(
                            child: TextButton.icon(
                              onPressed: _pickImageFromStorage,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'Cargar desde almacenamiento interno',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Campo Nombre del Producto
                          const Text(
                            'Nombre del producto',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nombreController,
                            validator: (val) => Validators.validateRequired(
                              val,
                              'nombre del producto',
                            ),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej. Vitamina C 1000mg',
                              hintStyle: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderFocus,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo Descripcion
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descripcionController,
                            minLines: 3,
                            maxLines: 4,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Describe la dosificación, contraindicaciones y presentación...',
                              hintStyle: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderFocus,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Fila Precio y Stock Actual
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Precio (\$)',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _precioController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: Validators.validatePrice,
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '12.99',
                                        hintStyle: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 15,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.borderFocus,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stock Actual',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _stockController,
                                      keyboardType: TextInputType.number,
                                      validator: Validators.validateStock,
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '24',
                                        hintStyle: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 15,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.borderFocus,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Boton Guardar Cambios
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
                              onPressed: _isLoading
                                  ? null
                                  : _handleUpdateProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary
                                    .withValues(alpha: 0.7),
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
                                      'Guardar cambios',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Si tenemos bytes locales cargados desde almacenamiento
    if (_localImageBytes != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(
              _localImageBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                onPressed: () {
                  setState(() {
                    _localImageBytes = null;
                    _photoUrl = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    // Si tenemos URL remota
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              _photoUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPhotoPlaceholder(),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                onPressed: () {
                  setState(() {
                    _photoUrl = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return _buildPhotoPlaceholder();
  }

  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: AppColors.primary,
        ),
        SizedBox(height: 8),
        Text(
          'Toca para seleccionar o cambiar foto',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Almacenamiento interno o enlace web',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
