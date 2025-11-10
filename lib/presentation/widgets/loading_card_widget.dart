import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar estado de carga
class LoadingCardWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final bool showCancelButton;
  final VoidCallback? onCancel;

  const LoadingCardWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.showCancelButton = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showCancelButton && onCancel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(
                    color: Colors.orange.shade700,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
