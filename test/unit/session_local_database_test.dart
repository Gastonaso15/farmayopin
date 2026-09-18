import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:farmayopin/data/local/compra_local_database.dart';
import 'package:farmayopin/data/models/auth_response.dart';
import 'package:farmayopin/data/models/user_session_model.dart';

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

  group('Session Local Database Tests', () {
    test('Guarda sesión y recupera sesión activa con remember_me', () async {
      final session = UserSessionModel(
        email: 'gaston@example.com',
        nombre: 'Gastón',
        token: 'jwt-token-123',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );

      await localDb.saveSession(session, plainPassword: 'password123');

      final active = await localDb.getActiveSession();
      expect(active, isNotNull);
      expect(active!.email, 'gaston@example.com');
      expect(active.nombre, 'Gastón');
      expect(active.token, 'jwt-token-123');
      expect(active.rol, UserRole.cliente);
      expect(active.rememberMe, isTrue);
      expect(active.isActive, isTrue);
    });

    test('Valida credenciales locales correctamente', () async {
      final session = UserSessionModel(
        email: 'maria@example.com',
        nombre: 'María',
        token: 'jwt-maria',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );

      await localDb.saveSession(session, plainPassword: 'MiPasswordSeguro!');

      // Contraseña correcta
      final valid = await localDb.validateLocalCredentials(
        'maria@example.com',
        'MiPasswordSeguro!',
      );
      expect(valid, isTrue);

      // Contraseña incorrecta
      final invalid = await localDb.validateLocalCredentials(
        'maria@example.com',
        'wrongpassword',
      );
      expect(invalid, isFalse);

      // Usuario no existente
      final noExiste = await localDb.validateLocalCredentials(
        'nadie@example.com',
        'cualquiera',
      );
      expect(noExiste, isFalse);
    });

    test('clearActiveSession desactiva la sesión pero preserva datos para login offline', () async {
      final session = UserSessionModel(
        email: 'pedro@example.com',
        nombre: 'Pedro',
        token: 'jwt-pedro',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );

      await localDb.saveSession(session, plainPassword: 'pedroPassword');
      expect(await localDb.getActiveSession(), isNotNull);

      await localDb.clearActiveSession();
      expect(await localDb.getActiveSession(), isNull);

      // Las credenciales siguen existiendo para poder hacer login local manual
      final valid = await localDb.validateLocalCredentials(
        'pedro@example.com',
        'pedroPassword',
      );
      expect(valid, isTrue);
    });

    test('Al activar una nueva sesión, se desactiva la anterior', () async {
      final session1 = UserSessionModel(
        email: 'user1@example.com',
        nombre: 'User 1',
        token: 'token-1',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );
      await localDb.saveSession(session1, plainPassword: 'pass1');

      final session2 = UserSessionModel(
        email: 'user2@example.com',
        nombre: 'User 2',
        token: 'token-2',
        rol: UserRole.cliente,
        rememberMe: true,
        isActive: true,
        lastLogin: DateTime.now(),
      );
      await localDb.saveSession(session2, plainPassword: 'pass2');

      final active = await localDb.getActiveSession();
      expect(active, isNotNull);
      expect(active!.email, 'user2@example.com');
    });
  });
}
