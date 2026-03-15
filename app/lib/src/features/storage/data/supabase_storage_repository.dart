import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/uploaded_image.dart';
import '../domain/storage_repository.dart';

class SupabaseStorageRepository implements StorageRepository {
  SupabaseStorageRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UploadedImage> uploadClothingImage({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final extension = p.extension(fileName).isEmpty ? '.jpg' : p.extension(fileName);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$extension';

    await _client.storage.from('clothing-images').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final signed = await _client.storage.from('clothing-images').createSignedUrl(
          path,
          60 * 60 * 24 * 30,
        );
    return UploadedImage(path: path, publicUrl: signed);
  }
}
