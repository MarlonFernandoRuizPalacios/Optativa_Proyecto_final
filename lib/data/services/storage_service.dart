import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _taskBucket = 'task-images';
  static const String _dishBucket = 'dishes';

  Future<String> uploadTaskImage({
    required Uint8List bytes,
    required String userId,
    String? filename,
    String? contentType,
  }) async {
    final name =
        filename ?? 'image-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}/$name';

    // Upload file with robust error handling
    try {
      await _client.storage
          .from(_taskBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: contentType ?? 'image/jpeg',
            ),
          );
    } on StorageException catch (e) {
      // Propagate a clear error to the caller (likely due to bucket/policies)
      throw Exception(
        'Fallo al subir imagen al bucket "$_taskBucket": ${e.message}',
      );
    } catch (e) {
      throw Exception('Fallo inesperado al subir imagen: $e');
    }

    // Try to return a signed URL (works for private buckets). If it fails, fallback to public URL.
    try {
      final signedUrl = await _client.storage
          .from(_taskBucket)
          .createSignedUrl(path, 60 * 60); // 1 hora
      return signedUrl;
    } catch (_) {
      // If bucket is public, this URL will work
      final publicUrl = _client.storage.from(_taskBucket).getPublicUrl(path);
      return publicUrl;
    }
  }

  // Methods for dish images
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$userId/$fileName';

      final bytes = await imageFile.readAsBytes();

      await _client.storage
          .from(_dishBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

      final String publicUrl = _client.storage
          .from(_dishBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_dishBucket);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) {
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from(_dishBucket).remove([filePath]);

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
