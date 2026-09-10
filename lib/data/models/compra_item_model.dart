class CompraItemModel {
  final int id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const CompraItemModel({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory CompraItemModel.fromJson(Map<String, dynamic> json) {
    return CompraItemModel(
      id: json['id'] as int? ?? 0,
      productoId: json['productoId'] as int? ?? 0,
      nombreProducto: json['nombreProducto'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
