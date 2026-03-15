import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/auth_state.dart';
import '../domain/auth_repository.dart';
import 'supabase_user_bootstrap_data_source.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client, {
    required this.bootstrapDataSource,
  });

  final SupabaseClient _client;
  final SupabaseUserBootstrapDataSource bootstrapDataSource;

  @override
  Future<AuthStateSnapshot> getCurrentAuthState() async {
    final user = _client.auth.currentUser;
    return AuthStateSnapshot(
      isAuthenticated: user != null,
      userId: user?.id,
      email: user?.email,
      isRemote: user != null,
    );
  }

  @override
  Future<AuthStateSnapshot> signInAnonymously() async {
    await _client.auth.signInAnonymously();
    return getCurrentAuthState();
  }

  @override
  Future<AuthStateSnapshot> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
    return getCurrentAuthState();
  }

  @override
  Future<AuthStateSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return getCurrentAuthState();
  }

  @override
  Future<AuthStateSnapshot> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
    );
    return getCurrentAuthState();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> bootstrapUserProfile(AuthStateSnapshot authState) async {
    if (!authState.isAuthenticated || authState.userId == null) return;
    await bootstrapDataSource.ensureUserProfile(
      userId: authState.userId!,
      email: authState.email,
    );
  }
}
