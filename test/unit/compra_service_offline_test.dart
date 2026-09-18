import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:farmayopin/data/local/compra_local_database.dart';
import 'package:farmayopin/data/models/compra_item_model.dart';
import 'package:farmayopin/data/models/compra_model.dart';
import 'package:farmayopin/data/services/compra_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CompraLocalDatabase localDb;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: CompraLocalDatabase.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${CompraLocalDatabase.tableCompras} (
            id INTEGER PRIMARY KEY,
            user_email TEXT NOT NULL,
            fecha TEXT NOT NULL,
            total REAL NOT NULL,
            cliente_nombre TEXT NOT NULL,
            cliente_email TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ${CompraLocalDatabase.tableCompraItems} (
            id INTEGER PRIMARY KEY,
            compra_id INTEGER NOT NULL,
            producto_id INTEGER NOT NULL,
            nombre_producto TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (compra_id) REFERENCES ${CompraLocalDatabase.tableCompras}(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    localDb = CompraLocalDatabase(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CompraService Offline & Replication Tests', () {
    test('Online: replica datos en SQLite y retorna isFromLocalDatabase false',
        () async {
      final mockResponse = [
        {
          'id': 1,
          'fecha': '2026-03-10T12:00:00Z',
          'total': 500.0,
          'clienteNombre': 'Gastón Pérez',
          'clienteEmail': 'gaston@example.com',
          'items': [
            {
              'id': 1,
              'productoId': 10,
              'nombreProducto': 'Ibuprofeno',
              'cantidad': 2,
              'precioUnitario': 250.0,
              'subtotal': 500.0,
            }
          ]
        }
      ];

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = CompraService(
        client: mockClient,
        localDatabase: localDb,
      );

      final result = await service.getHistorialResult(
        token: 'fake-token',
        userEmail: 'gaston@example.com',
      );

      expect(result.isFromLocalDatabase, isFalse);
      expect(result.compras.length, 1);
      expect(result.compras.first.id, 1);

      // Verificar que los datos se replicaron efectivamente en la base local SQLite
      final localCompras = await localDb.getComprasByUser('gaston@example.com');
      expect(localCompras.length, 1);
      expect(localCompras.first.id, 1);
      expect(localCompras.first.items.first.nombreProducto, 'Ibuprofeno');
    });

    test(
        'Offline (SocketException): recupera datos desde SQLite con isFromLocalDatabase true',
        () async {
      // Pre-cargar datos en la base SQLite local
      final preloadedCompra = CompraModel(
        id: 99,
        fecha: DateTime(2026, 3, 5),
        total: 300.0,
        clienteNombre: 'Gastón Pérez',
        clienteEmail: 'gaston@example.com',
        items: const [
          CompraItemModel(
            id: 1,
            productoId: 20,
            nombreProducto: 'Amoxicilina',
            cantidad: 1,
            precioUnitario: 300.0,
            subtotal: 300.0,
          ),
        ],
      );
      await localDb.saveCompra(preloadedCompra, userEmail: 'gaston@example.com');

      // Mock cliente que simula pérdida de conexión
      final mockClient = MockClient((request) async {
        throw const SocketException('No route to host');
      });

      final service = CompraService(
        client: mockClient,
        localDatabase: localDb,
      );

      final result = await service.getHistorialResult(
        token: 'fake-token',
        userEmail: 'gaston@example.com',
      );

      expect(result.isFromLocalDatabase, isTrue);
      expect(result.compras.length, 1);
      expect(result.compras.first.id, 99);
      expect(result.compras.first.items.first.nombreProducto, 'Amoxicilina');
      expect(result.noticeMessage, contains('Sin conexión con el servidor'));
    });

    test('Servidor caído (HTTP 500): recurre a los datos locales si existen',
        () async {
      final preloadedCompra = CompraModel(
        id: 42,
        fecha: DateTime(2026, 3, 6),
        total: 150.0,
        clienteNombre: 'Gastón',
        clienteEmail: 'gaston@example.com',
        items: const [],
      );
      await localDb.saveCompra(preloadedCompra, userEmail: 'gaston@example.com');

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = CompraService(
        client: mockClient,
        localDatabase: localDb,
      );

      final result = await service.getHistorialResult(
        token: 'fake-token',
        userEmail: 'gaston@example.com',
      );

      expect(result.isFromLocalDatabase, isTrue);
      expect(result.compras.first.id, 42);
      expect(result.noticeMessage, contains('servidor no está disponible'));
    });

    test(
        'Offline sin datos locales: lanza CompraException con mensaje adecuado',
        () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Network down');
      });

      final service = CompraService(
        client: mockClient,
        localDatabase: localDb,
      );

      expect(
        () => service.getHistorialResult(
          token: 'fake-token',
          userEmail: 'nuevo_usuario@example.com',
        ),
        throwsA(isA<CompraException>()),
      );
    });

    test('saveCompraLocal persiste una compra individual en SQLite', () async {
      final service = CompraService(
        client: MockClient((r) async => http.Response('[]', 200)),
        localDatabase: localDb,
      );

      final compra = CompraModel(
        id: 777,
        fecha: DateTime(2026, 3, 15),
        total: 620.0,
        clienteNombre: 'Cliente Test',
        clienteEmail: 'test@example.com',
        items: [
          CompraItemModel(
            id: 1,
            productoId: 3,
            nombreProducto: 'Jarabe Tos',
            cantidad: 2,
            precioUnitario: 310.0,
            subtotal: 620.0,
          )
        ],
      );

      await service.saveCompraLocal(compra, userEmail: 'test@example.com');

      final list = await localDb.getComprasByUser('test@example.com');
      expect(list.length, 1);
      expect(list.first.id, 777);
      expect(list.first.items.first.nombreProducto, 'Jarabe Tos');
    });

    test('syncHistorialConServidor descarga y sincroniza compras en SQLite', () async {
      final mockData = [
        {
          'id': 555,
          'fecha': '2026-03-12T10:00:00Z',
          'total': 120.0,
          'clienteNombre': 'Ana',
          'clienteEmail': 'ana@example.com',
          'items': [
            {
              'id': 1,
              'productoId': 2,
              'nombreProducto': 'Termómetro',
              'cantidad': 1,
              'precioUnitario': 120.0,
              'subtotal': 120.0,
            }
          ]
        }
      ];

      final service = CompraService(
        client: MockClient((r) async => http.Response(jsonEncode(mockData), 200)),
        localDatabase: localDb,
      );

      final synced = await service.syncHistorialConServidor(
        token: 'token-sync',
        userEmail: 'ana@example.com',
      );

      expect(synced, isNotNull);
      expect(synced!.length, 1);
      expect(synced.first.id, 555);

      final guardadas = await localDb.getComprasByUser('ana@example.com');
      expect(guardadas.length, 1);
      expect(guardadas.first.id, 555);
      expect(guardadas.first.items.first.nombreProducto, 'Termómetro');
    });
  });
}
