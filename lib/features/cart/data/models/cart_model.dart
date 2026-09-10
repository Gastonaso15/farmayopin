import 'cart_item_model.dart';

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final double total;

  const CartModel({required this.id, required this.items, required this.total});

  bool get isEmpty => items.isEmpty;

  int get cantidadUnidades => items.fold(0, (sum, item) => sum + item.cantidad);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CartModel(
      id: json['id'] as int? ?? 0,
      items: rawItems
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static const CartModel empty = CartModel(id: 0, items: [], total: 0.0);
}
