/// Cloud boundary for the future Supabase implementation.
/// Product rule: one authenticated user owns one business profile.
abstract class CloudSyncService {
  Future<void> pushChanges();
  Future<void> pullChanges();
  Future<void> sync();
}
