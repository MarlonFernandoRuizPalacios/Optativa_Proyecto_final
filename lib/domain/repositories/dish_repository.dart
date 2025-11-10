import '../../domain/entities/dish_entity.dart';

abstract class DishRepository {
  Future<List<DishEntity>> getAllDishes(String userId);
  Future<DishEntity?> getDishById(String id);
  Future<bool> createDish(DishEntity dish);
  Future<bool> updateDish(DishEntity dish);
  Future<bool> deleteDish(String id);
}
