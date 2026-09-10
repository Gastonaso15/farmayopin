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
    return 'http://localhost:8080/$cleanPath';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      detalle: json['detalle'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      categoria: json['categoria'] as String? ?? 'Medicamentos',
    );
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
