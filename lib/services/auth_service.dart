import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  static const authRedirectUrl = 'invoiceeasy://auth/callback';

  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    // User-scoped local storage is initialized by _AuthenticatedHome after
    // the auth-state transition. Keeping scope switching here creates a race
    // with that startup gate and can make the business profile appear empty.
    return response;
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirectUrl,
    );

    // Scope migration is handled once by _AuthenticatedHome when a session
    // is established, not from the auth request and auth listener in parallel.
    return response;
  }

  Future<void> resendConfirmation(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: authRedirectUrl,
    );
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
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
