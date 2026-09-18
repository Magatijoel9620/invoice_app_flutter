import '../models/subscription_models.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<Subscription?> getCurrentSubscription();
  Future<Subscription> ensureSubscription();
  Future<Subscription> createTrial();
  Future<SubscriptionStatus> refreshSubscriptionStatus();
  Future<List<PaymentTransaction>> getPaymentTransactions();
  Future<PaymentTransaction> createPaymentIntent(String planCode);
}
