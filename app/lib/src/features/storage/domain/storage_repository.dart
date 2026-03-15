import '../../../shared/models/uploaded_image.dart';

abstract class StorageRepository {
  Future<UploadedImage> uploadClothingImage({
    required String userId,
    required List<int> bytes,
    required String fileName,
  });
}
