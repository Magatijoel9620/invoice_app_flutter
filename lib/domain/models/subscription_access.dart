import 'subscription_models.dart';

class SubscriptionAccess {
  const SubscriptionAccess({
    required this.status,
    required this.canRead,
    required this.canWrite,
    required this.daysRemaining,
  });

  final SubscriptionStatus status;
  final bool canRead;
  final bool canWrite;
  final int? daysRemaining;

  bool get requiresUpgrade => !canWrite;

  factory SubscriptionAccess.fromSubscription(Subscription? subscription) {
    if (subscription == null) {
      return const SubscriptionAccess(
        status: SubscriptionStatus.none,
        canRead: true,
        canWrite: false,
        daysRemaining: null,
      );
    }
    final end = subscription.accessEndsAt;
    final writable = subscription.hasAccess && (end == null || end.isAfter(DateTime.now().toUtc()));
    return SubscriptionAccess(
      status: subscription.status,
      canRead: true,
      canWrite: writable,
      daysRemaining: subscription.daysRemaining,
    );
  }
}
