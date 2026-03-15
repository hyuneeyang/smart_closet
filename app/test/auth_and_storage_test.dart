import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_closet/src/features/auth/data/mock_auth_repository.dart';
import 'package:smart_closet/src/features/storage/data/mock_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('mock auth 익명 로그인 후 인증 상태가 true 가 된다', () async {
    final repository = MockAuthRepository();
    final before = await repository.getCurrentAuthState();
    final after = await repository.signInAnonymously();

    expect(before.isAuthenticated, isFalse);
    expect(after.isAuthenticated, isTrue);
    expect(after.userId, isNotNull);
  });

  test('mock storage 업로드는 공개 URL을 반환한다', () async {
    final repository = MockStorageRepository();
    final uploaded = await repository.uploadClothingImage(
      userId: 'u1',
      bytes: [1, 2, 3],
      fileName: 'coat.jpg',
    );

    expect(uploaded.path, contains('u1'));
    expect(uploaded.publicUrl, contains('https://'));
  });
}
