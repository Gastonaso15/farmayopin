class TarjetaModel {
  final String id;
  final String tipo; // "CREDITO" o "DEBITO"
  final String marca; // "Visa", "Mastercard", "OCA", etc.
  final String ultimosCuatro;
  final String titular;
  final String vencimiento;
  final bool isDefault;

  const TarjetaModel({
    required this.id,
    required this.tipo,
    required this.marca,
    required this.ultimosCuatro,
    required this.titular,
    required this.vencimiento,
    this.isDefault = false,
  });

  String get titulo => '$marca ${tipo == "DEBITO" ? "Débito" : "Crédito"}';
  String get subtitulo => 'Terminada en $ultimosCuatro';

  factory TarjetaModel.fromJson(Map<String, dynamic> json) {
    return TarjetaModel(
      id: json['id'] != null ? json['id'].toString() : '',
      tipo: (json['tipo'] as String? ?? 'CREDITO').toUpperCase(),
      marca: json['marca'] as String? ?? 'Visa',
      ultimosCuatro: json['ultimosCuatro'] as String? ?? json['ultimos_cuatro'] as String? ?? '',
      titular: json['titular'] as String? ?? '',
      vencimiento: json['vencimiento'] as String? ?? '',
      isDefault: json['esPrincipal'] as bool? ?? json['es_principal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && int.tryParse(id) != null) 'id': int.parse(id),
      'tipo': tipo,
      'marca': marca,
      'ultimosCuatro': ultimosCuatro,
      'titular': titular,
      'vencimiento': vencimiento,
      'esPrincipal': isDefault,
    };
  }

  TarjetaModel copyWith({
    String? id,
    String? tipo,
    String? marca,
    String? ultimosCuatro,
    String? titular,
    String? vencimiento,
    bool? isDefault,
  }) {
    return TarjetaModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      marca: marca ?? this.marca,
      ultimosCuatro: ultimosCuatro ?? this.ultimosCuatro,
      titular: titular ?? this.titular,
      vencimiento: vencimiento ?? this.vencimiento,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
