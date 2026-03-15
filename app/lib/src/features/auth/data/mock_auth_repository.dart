import '../../../core/storage/local_session_store.dart';
import '../../../shared/models/auth_state.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({LocalSessionStore? localSessionStore})
      : _localSessionStore = localSessionStore ?? LocalSessionStore();

  final LocalSessionStore _localSessionStore;

  AuthStateSnapshot _state = const AuthStateSnapshot(
    isAuthenticated: false,
    isRemote: false,
  );

  @override
  Future<AuthStateSnapshot> getCurrentAuthState() async {
    final saved = await _localSessionStore.loadGuestAuthState();
    if (saved != null) {
      _state = saved;
    }
    return _state;
  }

  @override
  Future<AuthStateSnapshot> signInAnonymously() async {
    _state = const AuthStateSnapshot(
      isAuthenticated: true,
      userId: 'mock-user',
      email: 'mock@local.dev',
      isRemote: false,
    );
    await _localSessionStore.saveGuestAuthState(_state);
    return _state;
  }

  @override
  Future<AuthStateSnapshot> signInWithGoogle() async {
    _state = const AuthStateSnapshot(
      isAuthenticated: true,
      userId: 'mock-google-user',
      email: 'google@local.dev',
      isRemote: false,
    );
    await _localSessionStore.saveGuestAuthState(_state);
    return _state;
  }

  @override
  Future<AuthStateSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _state = AuthStateSnapshot(
      isAuthenticated: true,
      userId: 'mock-${email.hashCode}',
      email: email,
      isRemote: false,
    );
    await _localSessionStore.saveGuestAuthState(_state);
    return _state;
  }

  @override
  Future<AuthStateSnapshot> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _state = const AuthStateSnapshot(isAuthenticated: false, isRemote: false);
    await _localSessionStore.clearGuestAuthState();
  }

  @override
  Future<void> bootstrapUserProfile(AuthStateSnapshot authState) async {}
}
