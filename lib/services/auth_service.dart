import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_store.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user != null) {
      await LocalStore.switchToUserScope(user.id);
    }

    return response;
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user != null && response.session != null) {
      await LocalStore.switchToUserScope(user.id);
    }

    return response;
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    debugPrint('AUTH: signing out user ${_client.auth.currentUser?.id}');
    await _client.auth.signOut();
    debugPrint(
      'AUTH: sign out complete. '
      'currentUser=${_client.auth.currentUser?.id}, '
      'session=${_client.auth.currentSession}',
    );
  }
}
