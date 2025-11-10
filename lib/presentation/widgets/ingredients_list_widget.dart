import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Widget reutilizable para mostrar lista de ingredientes
class IngredientsListWidget extends StatelessWidget {
  final List<String> ingredients;
  final bool showTitle;
  final String title;

  const IngredientsListWidget({
    super.key,
    required this.ingredients,
    this.showTitle = true,
    this.title = 'Ingredientes:',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...ingredients.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
