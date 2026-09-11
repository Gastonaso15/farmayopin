class ProductoCompraHistorialModel {
  final int? compraId;
  final DateTime fecha;
  final int cantidad;
  final String cliente;
  final double precioUnitario;
  final double subtotal;

  const ProductoCompraHistorialModel({
    required this.compraId,
    required this.fecha,
    required this.cantidad,
    required this.cliente,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ProductoCompraHistorialModel.fromJson(Map<String, dynamic> json) {
    return ProductoCompraHistorialModel(
      compraId: json['compraId'] as int?,
      fecha:
          DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      cantidad: json['cantidad'] as int? ?? 0,
      cliente: json['cliente'] as String? ?? 'Desconocido',
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
