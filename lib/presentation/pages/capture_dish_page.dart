import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dish_controller.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/action_button_widget.dart';
import '../widgets/loading_card_widget.dart';
import '../widgets/error_card_widget.dart';
import '../widgets/ingredients_list_widget.dart';
import '../../core/constants/app_colors.dart';

class CaptureDishPage extends StatelessWidget {
  const CaptureDishPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DishController controller = Get.put(DishController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Platillo'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Image preview widget
              ImagePreviewWidget(
                imageFile: controller.selectedImage.value,
                height: 300,
                placeholderText: 'Toma una foto o selecciona una imagen',
                placeholderIcon: Icons.camera_alt,
              ),
              const SizedBox(height: 20),

              // Instructions
              if (controller.selectedImage.value == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '📸 Toma una foto nueva o 🖼️ selecciona una existente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Buttons for camera and gallery
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isAnalyzing.value
                          ? null
                          : () => controller.pickImageFromCamera(),
                      icon: const Icon(Icons.camera_alt, size: 22),
                      label: const Text(
                        'Tomar\nFoto',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isAnalyzing.value
                          ? null
                          : () => controller.pickImageFromGallery(),
                      icon: const Icon(Icons.photo_library, size: 22),
                      label: const Text(
                        'Subir\nImagen',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Options for changing or retrying
              if (controller.selectedImage.value != null &&
                  !controller.isAnalyzing.value)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => controller.clearSelection(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Cambiar imagen'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                        ),
                      ),
                      // Show retry button only if analysis has been done AND it's not a "not food" error
                      if (controller.analysisResult.value.isNotEmpty &&
                          !controller.errorMessage.value.contains('no contiene comida')) ...[
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => controller.analyzeImage(),
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Reintentar análisis'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Analysis result - usando widgets
              if (controller.isAnalyzing.value)
                LoadingCardWidget(
                  message: '☁️ Analizando imagen con IA...',
                  subtitle: 'Esto puede tomar unos segundos',
                  showCancelButton: true,
                  onCancel: () => controller.cancelAnalysis(),
                )
              // Show error card if analysis failed
              else if (controller.analysisError.value)
                ErrorCardWidget(
                  title: controller.errorMessage.value.contains('no contiene comida') 
                      ? 'No es comida'
                      : 'Error en el análisis',
                  message: controller.errorMessage.value,
                  // Only show retry button if it's a real error, not "not food"
                  onRetry: controller.errorMessage.value.contains('no contiene comida')
                      ? null
                      : () => controller.analyzeImage(),
                  retryButtonText: 'Reintentar Análisis',
                )
              else if (controller.analysisResult.value.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Análisis del Platillo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nombre:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.analyzedData['dish_name'] ?? 'Desconocido',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        // Usar widget de ingredientes
                        IngredientsListWidget(
                          ingredients: (controller.analyzedData['ingredients'] as List?)
                              ?.map((e) => e.toString())
                              .toList() ?? [],
                        ),
                        if (controller.analyzedData['description'] != null &&
                            controller.analyzedData['description']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Descripción:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.analyzedData['description'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Retry button inside the analysis card
                        Center(
                          child: ActionButtonWidget(
                            onPressed: () => controller.analyzeImage(),
                            label: 'Reintentar Análisis',
                            icon: Icons.replay,
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.accentBlue,
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Save button (only show if it's actually food)
              if (controller.selectedImage.value != null &&
                  controller.analysisResult.value.isNotEmpty &&
                  !controller.isAnalyzing.value &&
                  !controller.analysisError.value &&
                  controller.analyzedData['dish_name'] != 'No es comida' &&
                  (controller.analyzedData['ingredients'] as List?)?.isNotEmpty == true)
                ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.saveDish(),
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    controller.isLoading.value
                        ? 'Guardando...'
                        : 'Guardar Platillo',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        );
        }),
      ),
    );
  }
}
