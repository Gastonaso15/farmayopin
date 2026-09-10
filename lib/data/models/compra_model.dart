import 'compra_item_model.dart';

class CompraModel {
  final int id;
  final DateTime fecha;
  final double total;
  final String clienteNombre;
  final String clienteEmail;
  final List<CompraItemModel> items;

  const CompraModel({
    required this.id,
    required this.fecha,
    required this.total,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.items,
  });

  /// Suma de los subtotales de cada item. En este sistema no existen cargos
  /// adicionales (envío, impuestos, etc.), por lo que coincide con [total].
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CompraModel(
      id: json['id'] as int? ?? 0,
      fecha:
          DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      clienteNombre: json['clienteNombre'] as String? ?? '',
      clienteEmail: json['clienteEmail'] as String? ?? '',
      items: rawItems
          .map(
            (item) => CompraItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
