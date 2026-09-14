import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AccountProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  const AccountProfile({required this.id, required this.email, this.fullName = '', this.phone = ''});
}

class AccountProfileService {
  SupabaseClient get _client => SupabaseService.client;

  Future<AccountProfile> get() async {
    final user = _client.auth.currentUser!;
    final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    return AccountProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: row?['full_name'] as String? ?? (user.userMetadata?['full_name'] as String? ?? ''),
      phone: row?['phone'] as String? ?? '',
    );
  }

  Future<void> save({required String fullName, required String phone}) async {
    final user = _client.auth.currentUser!;
    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
