import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/subscription_models.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../services/supabase_service.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseClient get _db => SupabaseService.client;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final rows = await _db.from('subscription_plans').select().eq('is_active', true).order('price');
    return (rows as List).map((row) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  @override
  Future<Subscription?> getCurrentSubscription() async {
    final rows = await _db.from('subscriptions').select().order('created_at', ascending: false).limit(1);
    if (rows.isEmpty) return null;
    return Subscription.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  @override
  Future<Subscription> ensureSubscription() async {
    final existing = await getCurrentSubscription();
    if (existing != null) return existing;
    return createTrial();
  }

  @override
  Future<Subscription> createTrial() async {
    final response = await _db.rpc('create_trial_subscription');
    return Subscription.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<SubscriptionStatus> refreshSubscriptionStatus() async {
    final response = await _db.rpc('refresh_subscription_status');
    return _parseStatus(response.toString());
  }

  @override
  Future<List<PaymentTransaction>> getPaymentTransactions() async {
    final rows = await _db.from('payment_transactions').select().order('created_at', ascending: false).limit(20);
    return (rows as List).map((row) => PaymentTransaction.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  @override
  Future<PaymentTransaction> createPaymentIntent(String planCode) async {
    final response = await _db.rpc('create_payment_intent', params: {'requested_plan_code': planCode});
    return PaymentTransaction.fromJson(Map<String, dynamic>.from(response as Map));
  }

  SubscriptionStatus _parseStatus(String value) => switch (value) {
        'trialing' => SubscriptionStatus.trialing,
        'active' => SubscriptionStatus.active,
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        'past_due' => SubscriptionStatus.pastDue,
        _ => SubscriptionStatus.none,
      };
}
