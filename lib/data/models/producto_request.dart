class ProductoRequest {
  final String nombre;
  final double precio;
  final String? detalle;
  final String? foto;
  final int stock;

  const ProductoRequest({
    required this.nombre,
    required this.precio,
    this.detalle,
    this.foto,
    required this.stock,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'precio': precio,
      'detalle': detalle,
      'foto': foto,
      'stock': stock,
    };
  }
}
