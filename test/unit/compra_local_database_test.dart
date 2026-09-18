import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:farmayopin/data/local/compra_local_database.dart';
import 'package:farmayopin/data/models/compra_item_model.dart';
import 'package:farmayopin/data/models/compra_model.dart';

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
          CREATE INDEX idx_compras_user_email ON ${CompraLocalDatabase.tableCompras}(user_email)
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

  group('CompraLocalDatabase Tests', () {
    test('Guarda y recupera compras con sus items correctamente', () async {
      final items = [
        const CompraItemModel(
          id: 1,
          productoId: 10,
          nombreProducto: 'Ibuprofeno 400mg',
          cantidad: 2,
          precioUnitario: 150.0,
          subtotal: 300.0,
        ),
        const CompraItemModel(
          id: 2,
          productoId: 11,
          nombreProducto: 'Paracetamol 500mg',
          cantidad: 1,
          precioUnitario: 120.0,
          subtotal: 120.0,
        ),
      ];

      final compra = CompraModel(
        id: 101,
        fecha: DateTime(2026, 3, 10, 14, 30),
        total: 420.0,
        clienteNombre: 'Gastón',
        clienteEmail: 'gaston@example.com',
        items: items,
      );

      await localDb.saveCompras([compra], userEmail: 'gaston@example.com');

      final recuperadas = await localDb.getComprasByUser('gaston@example.com');
      expect(recuperadas.length, 1);

      final c = recuperadas.first;
      expect(c.id, 101);
      expect(c.total, 420.0);
      expect(c.clienteNombre, 'Gastón');
      expect(c.clienteEmail, 'gaston@example.com');
      expect(c.items.length, 2);
      expect(c.items[0].nombreProducto, 'Ibuprofeno 400mg');
      expect(c.items[0].cantidad, 2);
      expect(c.items[1].nombreProducto, 'Paracetamol 500mg');
      expect(c.items[1].cantidad, 1);
    });

    test('Aislamiento por usuario: usuario B no ve compras de usuario A', () async {
      final compraA = CompraModel(
        id: 1,
        fecha: DateTime(2026, 3, 10),
        total: 100.0,
        clienteNombre: 'User A',
        clienteEmail: 'a@example.com',
        items: const [],
      );
      final compraB = CompraModel(
        id: 2,
        fecha: DateTime(2026, 3, 11),
        total: 200.0,
        clienteNombre: 'User B',
        clienteEmail: 'b@example.com',
        items: const [],
      );

      await localDb.saveCompras([compraA], userEmail: 'a@example.com');
      await localDb.saveCompras([compraB], userEmail: 'b@example.com');

      final comprasA = await localDb.getComprasByUser('a@example.com');
      final comprasB = await localDb.getComprasByUser('b@example.com');

      expect(comprasA.length, 1);
      expect(comprasA.first.id, 1);

      expect(comprasB.length, 1);
      expect(comprasB.first.id, 2);
    });

    test('Actualización: guardar compras existentes reemplaza sus items', () async {
      final compraV1 = CompraModel(
        id: 50,
        fecha: DateTime(2026, 3, 1),
        total: 100.0,
        clienteNombre: 'Gastón',
        clienteEmail: 'gaston@example.com',
        items: const [
          CompraItemModel(
            id: 1,
            productoId: 5,
            nombreProducto: 'Vitamina C',
            cantidad: 1,
            precioUnitario: 100.0,
            subtotal: 100.0,
          ),
        ],
      );

      await localDb.saveCompra(compraV1, userEmail: 'gaston@example.com');

      // Actualización con 2 items
      final compraV2 = CompraModel(
        id: 50,
        fecha: DateTime(2026, 3, 1),
        total: 250.0,
        clienteNombre: 'Gastón',
        clienteEmail: 'gaston@example.com',
        items: const [
          CompraItemModel(
            id: 1,
            productoId: 5,
            nombreProducto: 'Vitamina C',
            cantidad: 1,
            precioUnitario: 100.0,
            subtotal: 100.0,
          ),
          CompraItemModel(
            id: 2,
            productoId: 6,
            nombreProducto: 'Aspirina',
            cantidad: 1,
            precioUnitario: 150.0,
            subtotal: 150.0,
          ),
        ],
      );

      await localDb.saveCompra(compraV2, userEmail: 'gaston@example.com');

      final recuperadas = await localDb.getComprasByUser('gaston@example.com');
      expect(recuperadas.length, 1);
      expect(recuperadas.first.total, 250.0);
      expect(recuperadas.first.items.length, 2);
    });

    test('getCompraById retorna la compra correspondiente o null si no existe', () async {
      final compra = CompraModel(
        id: 77,
        fecha: DateTime(2026, 3, 1),
        total: 80.0,
        clienteNombre: 'Ana',
        clienteEmail: 'ana@example.com',
        items: const [
          CompraItemModel(
            id: 1,
            productoId: 2,
            nombreProducto: 'Alcohol en gel',
            cantidad: 1,
            precioUnitario: 80.0,
            subtotal: 80.0,
          ),
        ],
      );

      await localDb.saveCompra(compra, userEmail: 'ana@example.com');

      final encontrada = await localDb.getCompraById(77);
      expect(encontrada, isNotNull);
      expect(encontrada!.id, 77);
      expect(encontrada.items.first.nombreProducto, 'Alcohol en gel');

      final noExiste = await localDb.getCompraById(9999);
      expect(noExiste, isNull);
    });

    test('clearComprasByUser elimina las compras del usuario especificado', () async {
      final compra = CompraModel(
        id: 88,
        fecha: DateTime(2026, 3, 1),
        total: 50.0,
        clienteNombre: 'User',
        clienteEmail: 'user@example.com',
        items: const [],
      );

      await localDb.saveCompra(compra, userEmail: 'user@example.com');
      expect((await localDb.getComprasByUser('user@example.com')).length, 1);

      await localDb.clearComprasByUser('user@example.com');
      expect((await localDb.getComprasByUser('user@example.com')).length, 0);
    });
  });
}
