import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:farmayopin/data/local/compra_local_database.dart';
import 'package:farmayopin/data/models/auth_response.dart';
import 'package:farmayopin/data/models/compra_item_model.dart';
import 'package:farmayopin/data/models/compra_model.dart';
import 'package:farmayopin/data/models/user_session_model.dart';
import 'package:farmayopin/data/services/auth_service.dart';
import 'package:farmayopin/data/services/compra_service.dart';
import 'package:farmayopin/features/auth/presentation/screens/login_screen.dart';

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

        await db.execute('''
          CREATE TABLE ${CompraLocalDatabase.tableSessions} (
            email TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            token TEXT NOT NULL,
            rol TEXT NOT NULL,
            password_hash TEXT,
            remember_me INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 0,
            last_login TEXT NOT NULL
          )
        ''');
      },
    );
    localDb = CompraLocalDatabase(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LoginScreen Offline & Keep Session Tests', () {
    testWidgets('Muestra checkbox Mantener sesión iniciada y permite alternarlo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            localDatabase: localDb,
            authService: AuthService(
              client: MockClient((_) async => http.Response('{}', 200)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mantener sesión iniciada'), findsOneWidget);
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      // Estado inicial es false
      Checkbox checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);

      // Tocar en el texto o checkbox para activarlo
      await tester.tap(find.text('Mantener sesión iniciada'));
      await tester.pumpAndSettle();

      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isTrue);
    });

    testWidgets(
        'Login offline: ante SocketException y credenciales locales válidas navega a Historial local',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = UserSessionModel(
        email: 'cliente@example.com',
        nombre: 'Cliente Offline',
        token: 'token-offline',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );

      final compra = CompraModel(
        id: 999,
        fecha: DateTime(2026, 3, 1),
        total: 250.0,
        clienteNombre: 'Cliente Offline',
        clienteEmail: 'cliente@example.com',
        items: const [
          CompraItemModel(
            id: 1,
            productoId: 1,
            nombreProducto: 'Amoxicilina 500mg',
            cantidad: 1,
            precioUnitario: 250.0,
            subtotal: 250.0,
          ),
        ],
      );

      await tester.runAsync(() async {
        await localDb.saveSession(session, plainPassword: 'password123');
        await localDb.saveCompra(compra, userEmail: 'cliente@example.com');
      });

      // AuthService que simula caída de red (SocketException)
      final failingClient = MockClient((_) async {
        throw const SocketException('Servidor no alcanzable');
      });
      final authService = AuthService(client: failingClient);
      final compraService = CompraService(
        client: failingClient,
        localDatabase: localDb,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            localDatabase: localDb,
            authService: authService,
            compraService: compraService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'ejemplo@correo.com'),
        'cliente@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '••••••••••••'),
        'password123',
      );

      // Presionar Iniciar sesión y permitir que las consultas SQLite FFI finalicen
      await tester.runAsync(() async {
        await tester.tap(find.text('Iniciar sesión'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Debe haber ingresado a la pantalla de historial offline
      expect(find.text('Historial (Sin conexión)'), findsOneWidget);
      expect(find.text('#999'), findsOneWidget);
      expect(find.text('\$250.00'), findsOneWidget);
      expect(
        find.textContaining('Modo sin conexión'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(
        'Muestra botón directo de ver historial sin conexión si hay sesión previa guardada',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pre-guardar sesión activa
      final session = UserSessionModel(
        email: 'recordado@example.com',
        nombre: 'Usuario Recordado',
        token: 'token-rec',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );
      await tester.runAsync(() async {
        await localDb.saveSession(session, plainPassword: 'password123');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            localDatabase: localDb,
            authService: AuthService(
              client: MockClient((_) async => http.Response('{}', 200)),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Debe aparecer el botón directo para ver historial sin conexión
      expect(
        find.textContaining('Ver historial sin conexión (recordado@example.com)'),
        findsOneWidget,
      );

      // Tocar en el botón navega directamente al historial offline
      await tester.runAsync(() async {
        await tester.tap(find.textContaining('Ver historial sin conexión'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Historial (Sin conexión)'), findsOneWidget);
    });
  });
}
