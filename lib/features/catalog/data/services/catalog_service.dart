import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class CatalogService {
  final http.Client _client;

  CatalogService({http.Client? client}) : _client = client ?? http.Client();

  /// Lista productos desde el backend Spring Boot (`GET /api/productos`).
  /// Si el backend no está disponible, retorna productos por defecto de Figma para testing y UX fluida.
  Future<List<ProductModel>> getProductos({String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/productos');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        return getMockProducts();
      }
    } on SocketException {
      // Si el servidor está offline, usamos los productos mock de Figma
      return getMockProducts();
    } on http.ClientException {
      return getMockProducts();
    } catch (_) {
      return getMockProducts();
    }
  }

  static List<ProductModel> getMockProducts() {
    return const [
      ProductModel(
        id: 1,
        nombre: 'Vitamina C 1000mg',
        precio: 12.99,
        detalle: 'Suplemento antioxidante para fortalecer el sistema inmune.',
        foto: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300&q=80',
        stock: 24,
        categoria: 'Vitaminas',
      ),
      ProductModel(
        id: 2,
        nombre: 'Ibuprofeno 400mg',
        precio: 3.45,
        detalle: 'Antiinflamatorio y analgésico de rápida acción.',
        foto: 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=300&q=80',
        stock: 150,
        categoria: 'Medicamentos',
      ),
      ProductModel(
        id: 3,
        nombre: 'Protector Solar SPF50',
        precio: 24.99,
        detalle: 'Alta protección UVA/UVB resistente al agua.',
        foto: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&q=80',
        stock: 12,
        categoria: 'Cuidado Personal',
      ),
      ProductModel(
        id: 4,
        nombre: 'Paracetamol 500mg',
        precio: 2.99,
        detalle: 'Alivio eficaz del dolor de cabeza y la fiebre.',
        foto: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=300&q=80',
        stock: 85,
        categoria: 'Medicamentos',
      ),
      ProductModel(
        id: 5,
        nombre: 'Complejo B Multivitamínico',
        precio: 15.50,
        detalle: 'Energía y soporte para el sistema nervioso.',
        foto: 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=300&q=80',
        stock: 30,
        categoria: 'Vitaminas',
      ),
      ProductModel(
        id: 6,
        nombre: 'Alcohol en Gel 250ml',
        precio: 4.20,
        detalle: 'Sanitizante antibacteriano instantáneo con aloe vera.',
        foto: 'https://images.unsplash.com/photo-1584744982491-665216d95f8b?w=300&q=80',
        stock: 45,
        categoria: 'Cuidado Personal',
      ),
    ];
  }
}
