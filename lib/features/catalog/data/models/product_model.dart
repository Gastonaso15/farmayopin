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
