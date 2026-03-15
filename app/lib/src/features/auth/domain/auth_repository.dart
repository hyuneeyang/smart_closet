import '../../../shared/models/auth_state.dart';

abstract class AuthRepository {
  Future<AuthStateSnapshot> getCurrentAuthState();
  Future<AuthStateSnapshot> signInAnonymously();
  Future<AuthStateSnapshot> signInWithGoogle();
  Future<AuthStateSnapshot> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AuthStateSnapshot> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> bootstrapUserProfile(AuthStateSnapshot authState);
}
