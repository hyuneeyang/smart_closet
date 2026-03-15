import '../../../shared/models/uploaded_image.dart';
import '../domain/storage_repository.dart';

class MockStorageRepository implements StorageRepository {
  @override
  Future<UploadedImage> uploadClothingImage({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final seed = fileName.isEmpty ? 'closet' : Uri.encodeComponent(fileName);
    return UploadedImage(
      path: '$userId/$seed',
      publicUrl: 'https://picsum.photos/seed/$seed/600/600',
    );
  }
}
