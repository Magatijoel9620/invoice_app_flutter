import '../../domain/models/subscription_models.dart';
import '../../domain/repositories/subscription_repository.dart';

class DemoSubscriptionRepository implements SubscriptionRepository {
  final _now = DateTime.now().toUtc();
  @override
  Future<List<SubscriptionPlan>> getPlans() async => [
    SubscriptionPlan(id: 'trial', code: 'trial', name: 'Free Trial', description: '14 days of full InvoiceEasy access.', durationDays: 14, price: 0, currency: 'KES', isActive: true, createdAt: _now, updatedAt: _now),
    SubscriptionPlan(id: 'monthly', code: 'monthly', name: 'Monthly', description: 'Full access, billed every month.', durationDays: 30, price: 200, currency: 'KES', isActive: true, createdAt: _now, updatedAt: _now),
    SubscriptionPlan(id: 'annual', code: 'annual', name: 'Yearly', description: 'Save KSh 400 compared with 12 monthly payments.', durationDays: 365, price: 2000, currency: 'KES', isActive: true, createdAt: _now, updatedAt: _now),
  ];
  @override Future<Subscription?> getCurrentSubscription() async => null;
  @override Future<Subscription> ensureSubscription() => createTrial();
  @override Future<Subscription> createTrial() async => throw UnimplementedError();
  @override Future<SubscriptionStatus> refreshSubscriptionStatus() async => SubscriptionStatus.none;
  @override Future<List<PaymentTransaction>> getPaymentTransactions() async => const [];
  @override Future<PaymentTransaction> createPaymentIntent(String planCode) async => throw UnimplementedError();
}
