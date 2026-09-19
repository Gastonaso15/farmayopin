import 'package:flutter/material.dart';

class DireccionModel {
  final String id;
  final String alias;
  final String calle;
  final String numero;
  final String pisoDepto;
  final String ciudad;
  final String departamento;
  final String codigoPostal;
  final String notas;
  final bool isDefault;
  final IconData icon;

  DireccionModel({
    required this.id,
    required this.alias,
    required this.calle,
    required this.numero,
    this.pisoDepto = '',
    this.ciudad = 'Maldonado',
    this.departamento = 'Maldonado',
    this.codigoPostal = '20000',
    this.notas = '',
    this.isDefault = false,
    IconData? icon,
  }) : icon = icon ?? resolverIcono(alias);

  static IconData resolverIcono(String alias) {
    final a = alias.toLowerCase();
    if (a.contains('casa') || a.contains('hogar') || a.contains('domicilio')) {
      return Icons.home_rounded;
    }
    if (a.contains('trabajo') || a.contains('oficina') || a.contains('empresa')) {
      return Icons.business_rounded;
    }
    if (a.contains('padre') || a.contains('madre') || a.contains('familia')) {
      return Icons.holiday_village_rounded;
    }
    return Icons.place_rounded;
  }

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    final alias = json['alias'] as String? ?? '';
    return DireccionModel(
      id: json['id'] != null ? json['id'].toString() : '',
      alias: alias,
      calle: json['calle'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      pisoDepto: json['pisoDepto'] as String? ?? json['piso_depto'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? 'Maldonado',
      departamento: json['departamento'] as String? ?? 'Maldonado',
      codigoPostal: json['codigoPostal'] as String? ?? json['codigo_postal'] as String? ?? '20000',
      notas: json['notas'] as String? ?? '',
      isDefault: json['esPrincipal'] as bool? ?? json['es_principal'] as bool? ?? false,
      icon: resolverIcono(alias),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && int.tryParse(id) != null) 'id': int.parse(id),
      'alias': alias,
      'calle': calle,
      'numero': numero,
      'pisoDepto': pisoDepto,
      'ciudad': ciudad,
      'departamento': departamento,
      'codigoPostal': codigoPostal,
      'notas': notas,
      'esPrincipal': isDefault,
    };
  }

  DireccionModel copyWith({
    String? id,
    String? alias,
    String? calle,
    String? numero,
    String? pisoDepto,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    String? notas,
    bool? isDefault,
    IconData? icon,
  }) {
    return DireccionModel(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      calle: calle ?? this.calle,
      numero: numero ?? this.numero,
      pisoDepto: pisoDepto ?? this.pisoDepto,
      ciudad: ciudad ?? this.ciudad,
      departamento: departamento ?? this.departamento,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      notas: notas ?? this.notas,
      isDefault: isDefault ?? this.isDefault,
      icon: icon ?? this.icon,
    );
  }
}
