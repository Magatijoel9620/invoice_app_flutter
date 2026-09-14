import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloud_config.dart';

class SupabaseService {
  static bool initialized = false;

  static Future<void> initialize() async {
    if (!CloudConfig.isConfigured || initialized) return;
    await Supabase.initialize(
      url: CloudConfig.url,
      publishableKey: CloudConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    initialized = true;
  }

  static SupabaseClient? get tryClient => initialized
      ? Supabase.instance.client
      : null;

  static SupabaseClient get client {
    if (!initialized) {
      throw StateError(
        'Supabase is not configured. Start InvoiceEasy with SUPABASE_URL '
        'and SUPABASE_PUBLISHABLE_KEY to enable cloud features.',
      );
    }
    return Supabase.instance.client;
  }
}
