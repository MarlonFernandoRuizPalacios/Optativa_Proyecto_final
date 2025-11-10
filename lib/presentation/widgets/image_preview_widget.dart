import 'dart:io';
import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar vista previa de imágenes
class ImagePreviewWidget extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final double height;
  final BoxFit fit;
  final String placeholderText;
  final IconData placeholderIcon;

  const ImagePreviewWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.height = 300,
    this.fit = BoxFit.cover,
    this.placeholderText = 'No hay imagen',
    this.placeholderIcon = Icons.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    // Priority: local file > network url > placeholder
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          placeholderIcon,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          placeholderText,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
