import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/dish_entity.dart';

/// Servicio para manejar base de datos local SQLite
class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'food_ai.db';
  static const int _databaseVersion = 1;

  // Tabla de platillos locales
  static const String _dishesTable = 'dishes_local';

  /// Obtener instancia de base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crear tablas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_dishesTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        imageUrl TEXT,
        imageLocalPath TEXT,
        description TEXT,
        createdAt INTEGER NOT NULL,
        syncedWithServer INTEGER DEFAULT 0
      )
    ''');
  }

  /// Actualizar base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones aquí si es necesario
    if (oldVersion < 2) {
      // Ejemplo de migración
      // await db.execute('ALTER TABLE $_dishesTable ADD COLUMN newColumn TEXT');
    }
  }

  /// Guardar platillo localmente
  Future<bool> saveDish(DishEntity dish) async {
    try {
      final db = await database;
      await db.insert(
        _dishesTable,
        {
          'id': dish.id,
          'userId': dish.userId,
          'name': dish.name,
          'ingredients': dish.ingredients.join('|||'), // Separador especial
          'imageUrl': dish.imageUrl,
          'imageLocalPath': dish.imageLocalPath,
          'description': dish.description,
          'createdAt': dish.createdAt.millisecondsSinceEpoch,
          'syncedWithServer': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      print('Error saving dish locally: $e');
      return false;
    }
  }

  /// Obtener todos los platillos locales de un usuario
  Future<List<DishEntity>> getDishesByUserId(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _dishesTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => DishEntity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        ingredients: (map['ingredients'] as String).split('|||'),
        imageUrl: (map['imageUrl'] as String?) ?? '',
        imageLocalPath: map['imageLocalPath'] as String?,
        description: map['description'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      )).toList();
    } catch (e) {
      print('Error getting dishes from local database: $e');
      return [];
    }
  }

  /// Obtener platillo por ID
  Future<DishEntity?> getDishById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _dishesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final map = maps.first;
      return DishEntity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        ingredients: (map['ingredients'] as String).split('|||'),
        imageUrl: (map['imageUrl'] as String?) ?? '',
        imageLocalPath: map['imageLocalPath'] as String?,
        description: map['description'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
    } catch (e) {
      print('Error getting dish by id: $e');
      return null;
    }
  }

  /// Actualizar platillo
  Future<bool> updateDish(DishEntity dish) async {
    try {
      final db = await database;
      await db.update(
        _dishesTable,
        {
          'name': dish.name,
          'ingredients': dish.ingredients.join('|||'),
          'imageUrl': dish.imageUrl,
          'imageLocalPath': dish.imageLocalPath,
          'description': dish.description,
          'syncedWithServer': 0, // Marcar como no sincronizado
        },
        where: 'id = ?',
        whereArgs: [dish.id],
      );
      return true;
    } catch (e) {
      print('Error updating dish: $e');
      return false;
    }
  }

  /// Eliminar platillo
  Future<bool> deleteDish(String id) async {
    try {
      final db = await database;
      await db.delete(
        _dishesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting dish: $e');
      return false;
    }
  }

  /// Marcar platillo como sincronizado
  Future<bool> markAsSynced(String id) async {
    try {
      final db = await database;
      await db.update(
        _dishesTable,
        {'syncedWithServer': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error marking dish as synced: $e');
      return false;
    }
  }

  /// Obtener platillos no sincronizados
  Future<List<DishEntity>> getUnsyncedDishes(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _dishesTable,
        where: 'userId = ? AND syncedWithServer = ?',
        whereArgs: [userId, 0],
      );

      return maps.map((map) => DishEntity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        ingredients: (map['ingredients'] as String).split('|||'),
        imageUrl: (map['imageUrl'] as String?) ?? '',
        imageLocalPath: map['imageLocalPath'] as String?,
        description: map['description'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      )).toList();
    } catch (e) {
      print('Error getting unsynced dishes: $e');
      return [];
    }
  }

  /// Limpiar toda la base de datos (útil para logout)
  Future<bool> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_dishesTable);
      return true;
    } catch (e) {
      print('Error clearing database: $e');
      return false;
    }
  }

  /// Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
