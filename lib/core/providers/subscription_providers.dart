import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/demo/subscription_demo_repository.dart';
import '../../data/supabase/subscription_supabase_repository.dart';
import '../../domain/models/subscription_access.dart';
import '../../domain/models/subscription_models.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../services/supabase_service.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (!SupabaseService.initialized) return DemoSubscriptionRepository();
  return SupabaseSubscriptionRepository();
});

final subscriptionBootstrapProvider = FutureProvider<void>((ref) async {
  if (!SupabaseService.initialized || SupabaseService.client.auth.currentUser == null) return;
  final repo = ref.read(subscriptionRepositoryProvider);
  await repo.ensureSubscription();
  await repo.refreshSubscriptionStatus();
  ref.invalidate(currentSubscriptionProvider);
  ref.invalidate(subscriptionStatusProvider);
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) => ref.read(subscriptionRepositoryProvider).getPlans());
final currentSubscriptionProvider = FutureProvider<Subscription?>((ref) => ref.read(subscriptionRepositoryProvider).getCurrentSubscription());
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) => ref.read(subscriptionRepositoryProvider).refreshSubscriptionStatus());
final subscriptionAccessProvider = Provider<SubscriptionAccess>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.maybeWhen(data: (value) => SubscriptionAccess.fromSubscription(value), orElse: () => SubscriptionAccess.fromSubscription(null));
});
final paymentTransactionsProvider = FutureProvider<List<PaymentTransaction>>((ref) => ref.read(subscriptionRepositoryProvider).getPaymentTransactions());
