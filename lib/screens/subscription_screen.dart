import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/payment_engine_billing_providers.dart';
import '../core/providers/subscription_providers.dart';
import '../domain/models/subscription_models.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(currentSubscriptionProvider);
    final plans = ref.watch(subscriptionPlansProvider);
    final transactions = ref.watch(paymentTransactionsProvider);

    Future<void> refresh() async {
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionPlansProvider);
      ref.invalidate(paymentTransactionsProvider);
      await ref.read(currentSubscriptionProvider.future);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription & billing')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AccessCard(subscription: subscription.valueOrNull),
            const SizedBox(height: 24),
            Text(
              'Choose your plan',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep full InvoiceEasy access with monthly or yearly billing.',
            ),
            const SizedBox(height: 18),
            plans.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(subscriptionPlansProvider),
              ),
              data: (items) => LayoutBuilder(
                builder: (context, constraints) {
                  final paid = items
                      .where((p) => p.isActive && !p.isTrial)
                      .toList();
                  final cards = paid
                      .map(
                        (plan) => _PlanCard(
                          plan: plan,
                          onSubscribe: () => _choosePayment(context, ref, plan),
                        ),
                      )
                      .toList();
                  if (constraints.maxWidth >= 760) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards
                          .map(
                            (card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return Column(children: cards);
                },
              ),
            ),
            const SizedBox(height: 22),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your subscription is secure',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your subscription status is securely verified before access is activated. '
                      'Payments and subscription access are managed through our secure billing system.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            transactions.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment history',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            ...items
                                .take(8)
                                .map(
                                  (tx) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.receipt_long_outlined,
                                    ),
                                    title: Text(
                                      '${tx.currency} ${tx.amount.toStringAsFixed(0)}',
                                    ),
                                    subtitle: Text(
                                      '${tx.status.name} • ${tx.createdAt.toLocal()}',
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePayment(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Choose payment method',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_outlined),
              title: const Text('IntaSend'),
              subtitle: const Text('Secure hosted checkout with M-Pesa/card.'),
              onTap: () => Navigator.pop(sheetContext, 'intasend'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Manual M-Pesa'),
              subtitle: const Text(
                'Pay the InvoiceEasy Till and submit the reference.',
              ),
              onTap: () => Navigator.pop(sheetContext, 'manual_mpesa'),
            ),
          ],
        ),
      ),
    );
    if (method == null || !context.mounted) return;
    if (method == 'intasend') {
      await _startIntaSend(context, ref, plan);
    } else {
      await _startManual(context, ref, plan);
    }
  }

  Future<void> _startIntaSend(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    try {
      final service = ref.read(paymentEngineBillingServiceProvider);
      final intent = await service.createPaymentIntent(
        planId: plan.id,
        provider: 'intasend',
        idempotencyKey:
            'invoice_easy_${plan.code}_${DateTime.now().microsecondsSinceEpoch}',
      );
      final started = await service.startPayment(
        paymentIntentId: intent['id'].toString(),
        provider: 'intasend',
        method: 'mpesa',
      );
      if (!context.mounted) return;
      await _showPaymentStartedDialog(context, started);
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionStatusProvider);
      ref.invalidate(paymentTransactionsProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start IntaSend payment: $error')),
      );
    }
  }

  Future<void> _startManual(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    try {
      final service = ref.read(paymentEngineBillingServiceProvider);
      final snapshot = await service.snapshot();
      final settings = Map<String, dynamic>.from(
        snapshot['manual_payment'] as Map? ?? const {},
      );
      final intent = await service.createPaymentIntent(
        planId: plan.id,
        provider: 'manual_mpesa',
        idempotencyKey:
            'invoice_easy_manual_${plan.code}_${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!context.mounted) return;
      final reference = await _manualReferenceDialog(context, settings, plan);
      if (reference == null || reference.trim().isEmpty || !context.mounted) {
        return;
      }
      await service.submitManualPayment(
        paymentIntentId: intent['id'].toString(),
        reference: reference,
      );
      if (!context.mounted) return;
      ref.invalidate(paymentTransactionsProvider);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Payment submitted'),
          content: const Text(
            'Your M-Pesa reference has been submitted for verification. InvoiceEasy will activate access only after Payment Engine verification.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit M-Pesa payment: $error')),
      );
    }
  }

  Future<String?> _manualReferenceDialog(
    BuildContext context,
    Map<String, dynamic> settings,
    SubscriptionPlan plan,
  ) async {
    final controller = TextEditingController();
    final till = settings['till_number']?.toString() ?? '';
    final name = settings['till_name']?.toString() ?? 'InvoiceEasy';
    final instructions = settings['instructions']?.toString() ?? '';
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Manual M-Pesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay KSh ${plan.price.toStringAsFixed(0)} to $name${till.isEmpty ? '' : ' (Till $till)'}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(instructions),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa transaction code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Submit reference'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showPaymentStartedDialog(
    BuildContext context,
    Map<String, dynamic> response,
  ) async {
    final url = response['checkout_url']?.toString();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment started'),
        content: Text(
          response['customer_message']?.toString() ??
              'Complete payment using the secure checkout. Your subscription will activate after server-side verification.',
        ),
        actions: [
          if (url != null && url.isNotEmpty)
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Open payment'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.subscription});
  final Subscription? subscription;
  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final status = sub == null
        ? 'No subscription'
        : switch (sub.status) {
            SubscriptionStatus.trialing => 'Free trial',
            SubscriptionStatus.active => 'Active',
            SubscriptionStatus.expired => 'Expired',
            SubscriptionStatus.cancelled => 'Cancelled',
            SubscriptionStatus.pastDue => 'Payment due',
            SubscriptionStatus.none => 'No subscription',
          };
    final days = sub?.daysRemaining;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days == null
                        ? 'Billing access is controlled by the Payment Engine.'
                        : days == 1
                        ? '1 day remaining'
                        : '$days days remaining',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSubscribe});
  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;
  @override
  Widget build(BuildContext context) {
    final annual = plan.isAnnual;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(plan.description ?? ''),
            const SizedBox(height: 16),
            Text(
              'KSh ${plan.price.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(annual ? 'per year' : 'per month'),
            if (annual)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Save KSh 400 vs monthly billing',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...const [
              'Unlimited invoices',
              'Customers & products',
              'Professional PDF invoices',
              'Cloud backup & sync',
              'Reports & business records',
            ].map(
              (x) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 19),
                    const SizedBox(width: 9),
                    Expanded(child: Text(x)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubscribe,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Continue to payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Text('Unable to load plans'),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
