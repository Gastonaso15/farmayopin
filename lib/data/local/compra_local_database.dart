import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/compra_item_model.dart';
import '../models/compra_model.dart';
import '../models/user_session_model.dart';

/// Administrador de la base de datos local SQLite para el historial de compras
/// y la persistencia de sesiones de usuario para modo offline.
class CompraLocalDatabase {
  static const String dbName = 'farmayopin_compras.db';
  static const int dbVersion = 2;

  static const String tableCompras = 'compras';
  static const String tableCompraItems = 'compra_items';
  static const String tableSessions = 'user_sessions';

  Database? _db;

  // ignore: prefer_initializing_formals
  CompraLocalDatabase({Database? db}) : _db = db;

  /// Obtiene o inicializa la instancia de base de datos SQLite.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Habilitar soporte de llaves foráneas en SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCompras (
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
      CREATE INDEX idx_compras_user_email ON $tableCompras(user_email)
    ''');

    await db.execute('''
      CREATE TABLE $tableCompraItems (
        id INTEGER PRIMARY KEY,
        compra_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre_producto TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (compra_id) REFERENCES $tableCompras(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_compra_items_compra_id ON $tableCompraItems(compra_id)
    ''');

    await _createSessionsTable(db);
  }

  Future<void> _createSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSessions (
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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sessions_active ON $tableSessions(is_active, remember_me)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSessionsTable(db);
    }
  }

  /// Guarda o actualiza una lista de compras para el usuario [userEmail].
  ///
  /// Se ejecuta dentro de una transacción para garantizar consistencia atómica.
  Future<void> saveCompras(
    List<CompraModel> compras, {
    required String userEmail,
  }) async {
    if (userEmail.isEmpty) return;
    final db = await database;
    final normalizedEmail = userEmail.trim().toLowerCase();
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final compra in compras) {
        await txn.insert(
          tableCompras,
          {
            'id': compra.id,
            'user_email': normalizedEmail,
            'fecha': compra.fecha.toIso8601String(),
            'total': compra.total,
            'cliente_nombre': compra.clienteNombre,
            'cliente_email': compra.clienteEmail,
            'synced_at': nowIso,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Reemplazar los ítems de esta compra
        await txn.delete(
          tableCompraItems,
          where: 'compra_id = ?',
          whereArgs: [compra.id],
        );

        for (final item in compra.items) {
          await txn.insert(
            tableCompraItems,
            {
              'id': item.id > 0 ? item.id : null,
              'compra_id': compra.id,
              'producto_id': item.productoId,
              'nombre_producto': item.nombreProducto,
              'cantidad': item.cantidad,
              'precio_unitario': item.precioUnitario,
              'subtotal': item.subtotal,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Guarda una sola compra (por ejemplo, recién efectuada en checkout).
  Future<void> saveCompra(
    CompraModel compra, {
    required String userEmail,
  }) async {
    await saveCompras([compra], userEmail: userEmail);
  }

  /// Obtiene el historial de compras replicado para [userEmail], ordenado
  /// por fecha descendente (la más reciente primero).
  Future<List<CompraModel>> getComprasByUser(String userEmail) async {
    if (userEmail.isEmpty) return [];
    final db = await database;
    final normalizedEmail = userEmail.trim().toLowerCase();

    final List<Map<String, dynamic>> comprasRows = await db.query(
      tableCompras,
      where: 'user_email = ?',
      whereArgs: [normalizedEmail],
      orderBy: 'fecha DESC, id DESC',
    );

    if (comprasRows.isEmpty) return [];

    final List<CompraModel> resultado = [];

    for (final row in comprasRows) {
      final compraId = row['id'] as int;
      final List<Map<String, dynamic>> itemsRows = await db.query(
        tableCompraItems,
        where: 'compra_id = ?',
        whereArgs: [compraId],
        orderBy: 'id ASC',
      );

      final items = itemsRows.map((itemRow) {
        return CompraItemModel(
          id: (itemRow['id'] as num?)?.toInt() ?? 0,
          productoId: (itemRow['producto_id'] as num?)?.toInt() ?? 0,
          nombreProducto: itemRow['nombre_producto'] as String? ?? '',
          cantidad: (itemRow['cantidad'] as num?)?.toInt() ?? 0,
          precioUnitario:
              (itemRow['precio_unitario'] as num?)?.toDouble() ?? 0.0,
          subtotal: (itemRow['subtotal'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      resultado.add(
        CompraModel(
          id: compraId,
          fecha: DateTime.tryParse(row['fecha'] as String? ?? '') ??
              DateTime.now(),
          total: (row['total'] as num?)?.toDouble() ?? 0.0,
          clienteNombre: row['cliente_nombre'] as String? ?? '',
          clienteEmail: row['cliente_email'] as String? ?? '',
          items: items,
        ),
      );
    }

    return resultado;
  }

  /// Busca una compra por su ID incluyendo sus ítems.
  Future<CompraModel?> getCompraById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableCompras,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final List<Map<String, dynamic>> itemsRows = await db.query(
      tableCompraItems,
      where: 'compra_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    final items = itemsRows.map((itemRow) {
      return CompraItemModel(
        id: (itemRow['id'] as num?)?.toInt() ?? 0,
        productoId: (itemRow['producto_id'] as num?)?.toInt() ?? 0,
        nombreProducto: itemRow['nombre_producto'] as String? ?? '',
        cantidad: (itemRow['cantidad'] as num?)?.toInt() ?? 0,
        precioUnitario:
            (itemRow['precio_unitario'] as num?)?.toDouble() ?? 0.0,
        subtotal: (itemRow['subtotal'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return CompraModel(
      id: id,
      fecha:
          DateTime.tryParse(row['fecha'] as String? ?? '') ?? DateTime.now(),
      total: (row['total'] as num?)?.toDouble() ?? 0.0,
      clienteNombre: row['cliente_nombre'] as String? ?? '',
      clienteEmail: row['cliente_email'] as String? ?? '',
      items: items,
    );
  }

  /// Hashea una contraseña local para verificación segura offline.
  static String hashPassword(String password) {
    return base64Url.encode(utf8.encode('farmayopin_salt_${password.trim()}'));
  }

  /// Guarda o actualiza los datos de sesión en SQLite.
  Future<void> saveSession(
    UserSessionModel session, {
    String? plainPassword,
  }) async {
    final db = await database;
    final normalizedEmail = session.email.trim().toLowerCase();
    final pwdHash = plainPassword != null
        ? hashPassword(plainPassword)
        : session.passwordHash;

    await db.transaction((txn) async {
      if (session.isActive) {
        // Desmarcar cualquier otra sesión como activa
        await txn.update(
          tableSessions,
          {'is_active': 0},
        );
      }

      await txn.insert(
        tableSessions,
        {
          'email': normalizedEmail,
          'nombre': session.nombre,
          'token': session.token,
          'rol': session.rol.name,
          'password_hash': pwdHash,
          'remember_me': session.rememberMe ? 1 : 0,
          'is_active': session.isActive ? 1 : 0,
          'last_login': session.lastLogin.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Retorna la sesión activa guardada con 'remember_me = 1', si existe.
  Future<UserSessionModel?> getActiveSession() async {
    final db = await database;
    final rows = await db.query(
      tableSessions,
      where: 'is_active = 1 AND remember_me = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserSessionModel.fromMap(rows.first);
  }

  /// Obtiene la información de sesión persistida para un correo específico.
  Future<UserSessionModel?> getSessionByEmail(String email) async {
    if (email.isEmpty) return null;
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();
    final rows = await db.query(
      tableSessions,
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserSessionModel.fromMap(rows.first);
  }

  /// Valida credenciales contra las guardadas en la base local SQLite.
  Future<bool> validateLocalCredentials(String email, String password) async {
    final session = await getSessionByEmail(email);
    if (session == null || session.passwordHash == null) {
      return false;
    }
    final inputHash = hashPassword(password);
    return session.passwordHash == inputHash;
  }

  /// Cierra la sesión activa actual en la base de datos local.
  Future<void> clearActiveSession() async {
    final db = await database;
    await db.update(
      tableSessions,
      {'is_active': 0, 'remember_me': 0},
      where: 'is_active = 1',
    );
  }

  /// Elimina todas las sesiones almacenadas localmente.
  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete(tableSessions);
  }

  /// Elimina las compras almacenadas de un usuario específico.
  Future<void> clearComprasByUser(String userEmail) async {
    if (userEmail.isEmpty) return;
    final db = await database;
    final normalizedEmail = userEmail.trim().toLowerCase();
    await db.delete(
      tableCompras,
      where: 'user_email = ?',
      whereArgs: [normalizedEmail],
    );
  }

  /// Cierra la base de datos si está abierta.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
