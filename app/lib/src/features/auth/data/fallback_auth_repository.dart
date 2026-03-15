import '../../../shared/models/auth_state.dart';
import '../domain/auth_repository.dart';

class FallbackAuthRepository implements AuthRepository {
  FallbackAuthRepository({
    required this.primary,
    required this.fallback,
  });

  final AuthRepository primary;
  final AuthRepository fallback;

  @override
  Future<AuthStateSnapshot> getCurrentAuthState() async {
    try {
      return await primary.getCurrentAuthState();
    } catch (_) {
      return fallback.getCurrentAuthState();
    }
  }

  @override
  Future<AuthStateSnapshot> signInAnonymously() async {
    try {
      return await primary.signInAnonymously();
    } catch (_) {
      return fallback.signInAnonymously();
    }
  }

  @override
  Future<AuthStateSnapshot> signInWithGoogle() {
    return primary.signInWithGoogle();
  }

  @override
  Future<AuthStateSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) {
    return primary.signInWithEmail(email: email, password: password);
  }

  @override
  Future<AuthStateSnapshot> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return primary.signUpWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    try {
      await primary.signOut();
    } catch (_) {
      // Ignore remote sign-out errors and still clear local fallback state.
    }
    await fallback.signOut();
  }

  @override
  Future<void> bootstrapUserProfile(AuthStateSnapshot authState) async {
    if (!authState.isRemote) return;
    await primary.bootstrapUserProfile(authState);
  }
}
