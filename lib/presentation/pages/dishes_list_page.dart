import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/dish_controller.dart';
import '../../core/constants/app_colors.dart';
import 'capture_dish_page.dart';
import 'dish_detail_page.dart';

class DishesListPage extends StatelessWidget {
  const DishesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DishController controller = Get.put(DishController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Platillos'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDishes(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.dishes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.dishes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  'No hay platillos guardados',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Text(
                  'Toma una foto para empezar',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadDishes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.dishes.length,
            itemBuilder: (context, index) {
              final dish = controller.dishes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Get.to(() => DishDetailPage(dish: dish));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          dish.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dish.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () {
                                    _showDeleteDialog(
                                      context,
                                      controller,
                                      dish.id,
                                      dish.imageUrl,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(dish.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: dish.ingredients
                                  .take(3)
                                  .map(
                                    (ingredient) => Chip(
                                      label: Text(
                                        ingredient,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: AppColors.lightPurple,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (dish.ingredients.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '+${dish.ingredients.length - 3} más',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const CaptureDishPage());
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Tomar Foto'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    DishController controller,
    String dishId,
    String imageUrl,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Platillo'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este platillo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteDish(dishId, imageUrl);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
