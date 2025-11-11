import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/dish_entity.dart';
import '../../domain/repositories/dish_repository.dart';
import '../../data/repositories/dish_repository_impl.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/storage_service.dart';
import '../../core/constants/app_colors.dart';

class DishController extends GetxController {
  final DishRepository _dishRepository = DishRepositoryImpl();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable variables
  final RxList<DishEntity> dishes = <DishEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAnalyzing = false.obs;
  final RxBool analysisError = false.obs;
  final RxBool analysisCancelled = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString analysisResult = ''.obs;
  final RxMap<String, dynamic> analyzedData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadDishes();
  }

  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<void> loadDishes() async {
    if (userId.isEmpty) return;

    isLoading.value = true;
    try {
      final result = await _dishRepository.getAllDishes(userId);
      dishes.value = result;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los platillos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await analyzeImage();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo tomar la foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await analyzeImage();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo seleccionar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> analyzeImage() async {
    if (selectedImage.value == null) return;

    isAnalyzing.value = true;
    analysisError.value = false;
    analysisCancelled.value = false;
    errorMessage.value = '';

    try {
      // Use AI service with Gemini
      final result = await _aiService.analyzeDishImage(selectedImage.value!);
      // final result = await _aiService.analyzeDishImageMock(selectedImage.value!);

      // Check if analysis was cancelled during the API call
      if (analysisCancelled.value) {
        return;
      }

      if (result['success'] == true) {
        analyzedData.value = result;
        
        // Check if the image is not food
        if (result['dish_name'] == 'No es comida' || 
            (result['ingredients'] as List).isEmpty) {
          analysisError.value = true;
          errorMessage.value = result['description'] ?? 'Esta imagen no contiene comida';
          analyzedData.clear(); // Clear data to prevent saving
          
          Get.snackbar(
            'No es comida',
            errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.warning, color: Colors.white),
          );
          return;
        }
        
        analysisResult.value =
            'Platillo: ${result['dish_name']}\n\nIngredientes:\n${(result['ingredients'] as List).join(', ')}';
        analysisError.value = false;
        
        Get.snackbar(
          'Análisis completado',
          'Imagen analizada con éxito',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successGreen.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        analysisError.value = true;
        errorMessage.value = result['error'] ?? 'No se pudo analizar la imagen';
        
        Get.snackbar(
          'Error en el análisis',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      // Don't show error if analysis was cancelled
      if (!analysisCancelled.value) {
        analysisError.value = true;
        errorMessage.value = 'Error al analizar la imagen: $e';
        
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } finally {
      if (!analysisCancelled.value) {
        isAnalyzing.value = false;
      }
    }
  }

  void cancelAnalysis() {
    analysisCancelled.value = true;
    isAnalyzing.value = false;
    
    Get.snackbar(
      'Análisis cancelado',
      'El análisis de la imagen fue cancelado',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.cancel, color: Colors.white),
    );
  }

  Future<void> saveDish() async {
    if (selectedImage.value == null || analyzedData.isEmpty) {
      Get.snackbar(
        'Error',
        'Primero debes tomar una foto y analizarla',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validate that it's actually food
    if (analyzedData['dish_name'] == 'No es comida' || 
        (analyzedData['ingredients'] as List?)?.isEmpty == true) {
      Get.snackbar(
        'Error',
        'No se puede guardar porque la imagen no contiene comida',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
      return;
    }

    if (userId.isEmpty) {
      Get.snackbar(
        'Error',
        'Debes iniciar sesión para guardar platillos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Upload image to Supabase Storage
      final imageUrl = await _storageService.uploadImage(
        selectedImage.value!,
        userId,
      );

      if (imageUrl == null) {
        throw Exception('No se pudo subir la imagen');
      }

      // Create dish entity
      final dish = DishEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: analyzedData['dish_name'] ?? 'Platillo',
        ingredients: List<String>.from(analyzedData['ingredients'] ?? []),
        imageUrl: imageUrl,
        imageLocalPath: selectedImage.value!.path,
        createdAt: DateTime.now(),
        description: analyzedData['description'],
      );

      // Save to database
      final success = await _dishRepository.createDish(dish);

      if (success) {
        dishes.insert(0, dish);
        clearSelection();
        Get.snackbar(
          'Éxito',
          'Platillo guardado correctamente',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back(); // Return to dishes list
      } else {
        throw Exception('No se pudo guardar el platillo');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo guardar el platillo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDish(String dishId, String imageUrl) async {
    isLoading.value = true;
    try {
      // Delete from database
      final success = await _dishRepository.deleteDish(dishId);

      if (success) {
        // Delete image from storage
        await _storageService.deleteImage(imageUrl);

        // Remove from list
        dishes.removeWhere((dish) => dish.id == dishId);

        Get.snackbar(
          'Éxito',
          'Platillo eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('No se pudo eliminar el platillo');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el platillo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearSelection() {
    selectedImage.value = null;
    analysisResult.value = '';
    analyzedData.clear();
  }
  
  @override
  void onClose() {
    super.onClose();
  }
}
