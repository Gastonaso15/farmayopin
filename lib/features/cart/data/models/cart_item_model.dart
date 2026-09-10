import '../../../../core/constants/api_constants.dart';

class CartItemModel {
  final int id;
  final int productoId;
  final String nombreProducto;
  final String foto;
  final double precioUnitario;
  final int cantidad;
  final double subtotal;

  const CartItemModel({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.foto,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
  });

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

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int? ?? 0,
      productoId: json['productoId'] as int? ?? 0,
      nombreProducto: json['nombreProducto'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      cantidad: json['cantidad'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
