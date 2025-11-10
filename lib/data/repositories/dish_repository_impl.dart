import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/dish_entity.dart';
import '../../domain/repositories/dish_repository.dart';
import '../services/local_database_service.dart';

class DishRepositoryImpl implements DishRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final String _tableName = 'dishes';

  @override
  Future<List<DishEntity>> getAllDishes(String userId) async {
    try {
      // Intentar obtener datos del servidor
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final serverDishes = (response as List)
          .map((dish) => DishEntity.fromJson(dish))
          .toList();
      
      // Guardar en base de datos local
      for (var dish in serverDishes) {
        await _localDb.saveDish(dish);
        await _localDb.markAsSynced(dish.id);
      }
      
      return serverDishes;
    } catch (e) {
      print('Error fetching dishes from server: $e');
      // Si falla, intentar obtener de la base de datos local
      try {
        final localDishes = await _localDb.getDishesByUserId(userId);
        print('Loaded ${localDishes.length} dishes from local database');
        return localDishes;
      } catch (localError) {
        print('Error fetching dishes from local database: $localError');
        return [];
      }
    }
  }

  @override
  Future<DishEntity?> getDishById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return DishEntity.fromJson(response);
    } catch (e) {
      print('Error fetching dish from server: $e');
      // Intentar desde base de datos local
      try {
        return await _localDb.getDishById(id);
      } catch (localError) {
        print('Error fetching dish from local database: $localError');
        return null;
      }
    }
  }

  @override
  Future<bool> createDish(DishEntity dish) async {
    // Guardar primero en base de datos local
    await _localDb.saveDish(dish);
    
    try {
      // Intentar guardar en servidor
      await _supabase.from(_tableName).insert(dish.toJson());
      // Marcar como sincronizado
      await _localDb.markAsSynced(dish.id);
      return true;
    } catch (e) {
      print('Error creating dish on server: $e');
      print('Dish saved locally, will sync later');
      // Aunque falle el servidor, el platillo está guardado localmente
      return true;
    }
  }

  @override
  Future<bool> updateDish(DishEntity dish) async {
    // Actualizar en base de datos local
    await _localDb.updateDish(dish);
    
    try {
      // Intentar actualizar en servidor
      await _supabase.from(_tableName).update(dish.toJson()).eq('id', dish.id);
      await _localDb.markAsSynced(dish.id);
      return true;
    } catch (e) {
      print('Error updating dish on server: $e');
      print('Dish updated locally, will sync later');
      return true;
    }
  }

  @override
  Future<bool> deleteDish(String id) async {
    // Eliminar de base de datos local
    await _localDb.deleteDish(id);
    
    try {
      // Intentar eliminar del servidor
      await _supabase.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting dish from server: $e');
      return true; // Ya se eliminó localmente
    }
  }
  
  /// Sincronizar datos locales no sincronizados con el servidor
  Future<void> syncPendingChanges(String userId) async {
    try {
      final unsyncedDishes = await _localDb.getUnsyncedDishes(userId);
      
      for (var dish in unsyncedDishes) {
        try {
          // Intentar crear o actualizar en servidor
          await _supabase.from(_tableName).upsert(dish.toJson());
          await _localDb.markAsSynced(dish.id);
        } catch (e) {
          print('Error syncing dish ${dish.id}: $e');
        }
      }
    } catch (e) {
      print('Error syncing pending changes: $e');
    }
  }
}
