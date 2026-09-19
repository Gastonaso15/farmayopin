import '../../core/constants/api_constants.dart';

class ProductModel {
  final int id;
  final String nombre;
  final double precio;
  final String detalle;
  final String foto;
  final int stock;
  final String categoria;

  const ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.detalle,
    required this.foto,
    required this.stock,
    this.categoria = 'Medicamentos',
  });

  /// Resuelve la URL para visualización en la app móvil.
  /// Si es una ruta relativa almacenada en backend (ej: "img/..."), concatena con la URL base.
  String get imagenUrl {
    if (foto.isEmpty) return '';
    if (foto.startsWith('http://') ||
        foto.startsWith('https://') ||
        foto.startsWith('data:')) {
      return foto;
    }
    final cleanPath = foto.startsWith('/') ? foto.substring(1) : foto;
    return '${ApiConstants.baseUrl}/$cleanPath';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? '';
    final detalle = json['detalle'] as String? ?? '';
    return ProductModel(
      id: json['id'] as int? ?? 0,
      nombre: nombre,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      detalle: detalle,
      foto: json['foto'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      categoria: json['categoria'] as String? ??
          _inferirCategoria(nombre, detalle),
    );
  }

  static String _inferirCategoria(String nombre, String detalle) {
    final texto = '$nombre $detalle'.toLowerCase();
    if (texto.contains('vitamina') ||
        texto.contains('vitamín') ||
        texto.contains('suplemento') ||
        texto.contains('mineral')) {
      return 'Vitaminas';
    }
    if (texto.contains('alcohol') ||
        texto.contains('solar') ||
        texto.contains('fps') ||
        texto.contains('crema') ||
        texto.contains('gel') ||
        texto.contains('termómetro') ||
        texto.contains('termometro') ||
        texto.contains('gasas') ||
        texto.contains('venda') ||
        texto.contains('primeros auxilios') ||
        texto.contains('higiene') ||
        texto.contains('cuidado')) {
      return 'Cuidado Personal';
    }
    return 'Medicamentos';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'detalle': detalle,
      'foto': foto,
      'stock': stock,
      'categoria': categoria,
    };
  }
}
