import '../../domain/models/subscription_models.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../services/payment_engine_billing_service.dart';
import '../../services/supabase_service.dart';

class PaymentEngineSubscriptionRepository implements SubscriptionRepository {
  PaymentEngineSubscriptionRepository(this._billing);

  final PaymentEngineBillingService _billing;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final snapshot = await _billing.snapshot();
    return _plans(snapshot);
  }

  @override
  Future<Subscription?> getCurrentSubscription() async {
    final snapshot = await _billing.snapshot();
    return _subscription(snapshot);
  }

  @override
  Future<Subscription> ensureSubscription() async {
    final snapshot = await _billing.snapshot();
    final subscription = _subscription(snapshot);
    if (subscription == null) {
      throw StateError('Payment Engine did not return a subscription.');
    }
    return subscription;
  }

  @override
  Future<Subscription> createTrial() => ensureSubscription();

  @override
  Future<SubscriptionStatus> refreshSubscriptionStatus() async {
    final snapshot = await _billing.snapshot();
    return _subscription(snapshot)?.status ?? SubscriptionStatus.none;
  }

  @override
  Future<List<PaymentTransaction>> getPaymentTransactions() async {
    final snapshot = await _billing.snapshot();

    final intents = (snapshot['payment_intents'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final payments = (snapshot['payments'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final paymentsByIntentId = <String, Map<String, dynamic>>{};

    for (final payment in payments) {
      final intentId = payment['payment_intent_id']?.toString();

      if (intentId != null && intentId.isNotEmpty) {
        paymentsByIntentId[intentId] = payment;
      }
    }

    return intents.map((intent) {
      final intentId = intent['id']?.toString() ?? '';
      final payment = paymentsByIntentId[intentId];

      final centralStatus =
          (intent['status'] ?? payment?['status'] ?? 'pending')
              .toString()
              .toLowerCase();

      final status = switch (centralStatus) {
        'succeeded' => PaymentTransactionStatus.completed,
        'failed' => PaymentTransactionStatus.failed,
        'cancelled' => PaymentTransactionStatus.cancelled,
        'expired' => PaymentTransactionStatus.failed,
        _ => PaymentTransactionStatus.pending,
      };

      final amountMinor =
          (intent['amount'] as num?) ??
          (payment?['amount'] as num?) ??
          (intent['amount_minor'] as num?) ??
          (payment?['amount_minor'] as num?) ??
          0;

      final createdAt =
          DateTime.tryParse(intent['created_at']?.toString() ?? '') ??
          DateTime.now();

      final updatedAt =
          DateTime.tryParse(intent['updated_at']?.toString() ?? '') ??
          createdAt;

      return PaymentTransaction(
        // Use the payment-intent ID as the stable transaction ID.
        id: intentId,
        ownerId: SupabaseService.client.auth.currentUser!.id,
        subscriptionId: intent['subscription_id']?.toString(),
        planId: intent['plan_id']?.toString(),

        provider:
            intent['provider']?.toString() ??
            payment?['provider']?.toString() ??
            'payment_engine',

        providerTransactionId: payment?['id']?.toString(),

        providerReference:
            payment?['reference']?.toString() ??
            payment?['provider_reference']?.toString() ??
            intent['provider_invoice_id']?.toString() ??
            intent['external_reference']?.toString(),

        amount: amountMinor.toDouble() / 100,

        currency:
            intent['currency']?.toString() ??
            payment?['currency']?.toString() ??
            'KES',

        status: status,

        paymentMethod:
            intent['provider_method']?.toString() ??
            payment?['method']?.toString(),

        paidAt: centralStatus == 'succeeded'
            ? DateTime.tryParse(
                payment?['paid_at']?.toString() ??
                    intent['updated_at']?.toString() ??
                    '',
              )
            : null,

        failureReason: intent['failure_reason']?.toString(),

        metadata: {
          'payment_engine': true,
          'payment_intent_id': intentId,
          if (payment != null) 'payment_id': payment['id']?.toString(),
        },

        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }).toList();
  }

  @override
  Future<PaymentTransaction> createPaymentIntent(String planCode) async {
    final snapshot = await _billing.snapshot();
    final plan = (snapshot['plans'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (p) => p['code']?.toString() == planCode,
          orElse: () =>
              throw StateError('InvoiceEasy plan not found: $planCode'),
        );

    final intent = await _billing.createPaymentIntent(
      planId: plan['id'].toString(),
      provider: 'intasend',
      idempotencyKey:
          'invoice_easy_${planCode}_${DateTime.now().microsecondsSinceEpoch}',
    );

    final now = DateTime.now().toUtc();
    return PaymentTransaction(
      id: intent['id']?.toString() ?? '',
      ownerId: SupabaseService.client.auth.currentUser!.id,
      subscriptionId: intent['subscription_id']?.toString(),
      planId: plan['id']?.toString(),
      provider: intent['provider']?.toString() ?? 'intasend',
      providerTransactionId: null,
      providerReference: intent['external_reference']?.toString(),
      amount: ((intent['amount'] as num?) ?? 0).toDouble() / 100,
      currency: intent['currency']?.toString() ?? 'KES',
      status: PaymentTransactionStatus.pending,
      paymentMethod: intent['provider_method']?.toString(),
      paidAt: null,
      failureReason: intent['failure_reason']?.toString(),
      metadata: {'payment_engine': true},
      createdAt:
          DateTime.tryParse(intent['created_at']?.toString() ?? '') ?? now,
      updatedAt:
          DateTime.tryParse(intent['updated_at']?.toString() ?? '') ?? now,
    );
  }

  List<SubscriptionPlan> _plans(Map<String, dynamic> snapshot) {
    return (snapshot['plans'] as List? ?? const [])
        .map((raw) {
          final p = Map<String, dynamic>.from(raw as Map);
          return SubscriptionPlan(
            id: p['id'].toString(),
            code: p['code'].toString(),
            name: p['name']?.toString() ?? p['code'].toString(),
            description: p['description']?.toString(),
            durationDays: p['trial_days'] as int?,
            price: ((p['amount'] as num?) ?? 0).toDouble() / 100,
            currency: p['currency']?.toString() ?? 'KES',
            isActive: p['active'] == true,
            createdAt:
                DateTime.tryParse(p['created_at']?.toString() ?? '') ??
                DateTime.now().toUtc(),
            updatedAt:
                DateTime.tryParse(p['updated_at']?.toString() ?? '') ??
                DateTime.now().toUtc(),
          );
        })
        .where((p) => p.isActive)
        .toList();
  }

  Subscription? _subscription(Map<String, dynamic> snapshot) {
    final raw = snapshot['subscription'];
    if (raw is! Map) return null;
    final value = Map<String, dynamic>.from(raw);
    final status = switch (value['status']?.toString()) {
      'trial' => SubscriptionStatus.trialing,
      'active' => SubscriptionStatus.active,
      'past_due' => SubscriptionStatus.pastDue,
      'cancelled' => SubscriptionStatus.cancelled,
      'expired' => SubscriptionStatus.expired,
      _ => SubscriptionStatus.none,
    };
    final now = DateTime.now().toUtc();
    return Subscription(
      id: value['id']?.toString() ?? '',
      ownerId: SupabaseService.client.auth.currentUser!.id,
      planId: value['plan_id']?.toString() ?? '',
      status: status,
      startedAt:
          DateTime.tryParse(value['current_period_start']?.toString() ?? '') ??
          now,
      expiresAt: DateTime.tryParse(
        value['current_period_end']?.toString() ?? '',
      ),
      cancelledAt: null,
      autoRenew: value['cancel_at_period_end'] != true,
      trialEndsAt: DateTime.tryParse(value['trial_ends_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(value['created_at']?.toString() ?? '') ?? now,
      updatedAt:
          DateTime.tryParse(value['updated_at']?.toString() ?? '') ?? now,
    );
  }
}
