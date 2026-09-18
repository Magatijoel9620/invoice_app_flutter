enum SubscriptionStatus { trialing, active, expired, cancelled, pastDue, none }

enum PaymentTransactionStatus { pending, completed, failed, cancelled, refunded }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.durationDays,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final int? durationDays;
  final double price;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTrial => code == 'trial';
  bool get isFree => price <= 0;
  bool get isAnnual => code == 'annual';

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        durationDays: json['duration_days'] as int?,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'KES',
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class Subscription {
  const Subscription({
    required this.id,
    required this.ownerId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.cancelledAt,
    required this.autoRenew,
    this.trialEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final bool autoRenew;
  final DateTime? trialEndsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAccess => status == SubscriptionStatus.trialing || status == SubscriptionStatus.active;
  DateTime? get accessEndsAt => status == SubscriptionStatus.trialing ? trialEndsAt : expiresAt;
  int? get daysRemaining {
    final end = accessEndsAt;
    if (end == null) return null;
    final value = end.difference(DateTime.now().toUtc()).inDays;
    return value < 0 ? 0 : value;
  }

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        planId: json['plan_id'] as String,
        status: _status(json['status'] as String),
        startedAt: DateTime.parse(json['started_at'] as String),
        expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
        cancelledAt: json['cancelled_at'] == null ? null : DateTime.parse(json['cancelled_at'] as String),
        autoRenew: json['auto_renew'] as bool? ?? false,
        trialEndsAt: json['trial_ends_at'] == null ? null : DateTime.parse(json['trial_ends_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  static SubscriptionStatus _status(String value) => switch (value) {
        'trialing' => SubscriptionStatus.trialing,
        'active' => SubscriptionStatus.active,
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        'past_due' => SubscriptionStatus.pastDue,
        _ => SubscriptionStatus.none,
      };
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.ownerId,
    this.subscriptionId,
    this.planId,
    required this.provider,
    this.providerTransactionId,
    this.providerReference,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.paidAt,
    this.failureReason,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String? subscriptionId;
  final String? planId;
  final String provider;
  final String? providerTransactionId;
  final String? providerReference;
  final double amount;
  final String currency;
  final PaymentTransactionStatus status;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? failureReason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => PaymentTransaction(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        subscriptionId: json['subscription_id'] as String?,
        planId: json['plan_id'] as String?,
        provider: json['provider'] as String,
        providerTransactionId: json['provider_transaction_id'] as String?,
        providerReference: json['provider_reference'] as String?,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'KES',
        status: _paymentStatus(json['status'] as String),
        paymentMethod: json['payment_method'] as String?,
        paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
        failureReason: json['failure_reason'] as String?,
        metadata: json['metadata'] == null ? <String, dynamic>{} : Map<String, dynamic>.from(json['metadata'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  static PaymentTransactionStatus _paymentStatus(String value) => switch (value) {
        'pending' => PaymentTransactionStatus.pending,
        'completed' => PaymentTransactionStatus.completed,
        'failed' => PaymentTransactionStatus.failed,
        'cancelled' => PaymentTransactionStatus.cancelled,
        'refunded' => PaymentTransactionStatus.refunded,
        _ => PaymentTransactionStatus.pending,
      };
}
