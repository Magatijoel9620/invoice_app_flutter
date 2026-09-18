import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/subscription_providers.dart';
import '../domain/models/subscription_models.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(currentSubscriptionProvider);
    final plans = ref.watch(subscriptionPlansProvider);
    final transactions = ref.watch(paymentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentSubscriptionProvider);
          ref.invalidate(subscriptionPlansProvider);
          ref.invalidate(paymentTransactionsProvider);
          await ref.read(currentSubscriptionProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeroCard(subscription: subscription.valueOrNull),
            const SizedBox(height: 24),
            Text('Choose your plan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Simple KSh pricing. Full invoicing, customer, catalogue, reporting and cloud-sync access while your subscription is active.'),
            const SizedBox(height: 18),
            plans.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
              error: (e, _) => _ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(subscriptionPlansProvider)),
              data: (items) => LayoutBuilder(builder: (context, c) {
                final paid = items.where((p) => p.isActive && !p.isTrial).toList();
                final cards = paid.map((plan) => _PlanCard(plan: plan, onSubscribe: () => _startPayment(context, ref, plan))).toList();
                if (c.maxWidth >= 760) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards.map((x) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: x))).toList());
                return Column(children: cards.map((x) => Padding(padding: const EdgeInsets.only(bottom: 12), child: x)).toList());
              }),
            ),
            const SizedBox(height: 22),
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), const Text('Subscription protection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
              const SizedBox(height: 10),
              const Text('Subscription status is checked by Supabase. The app cannot mark a payment as completed or unlock paid access from the client.'),
            ]))),
            const SizedBox(height: 18),
            transactions.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) => items.isEmpty ? const SizedBox.shrink() : Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Recent payment requests', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...items.take(5).map((tx) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long_outlined), title: Text('${tx.currency} ${tx.amount.toStringAsFixed(0)}'), subtitle: Text('${tx.status.name} • ${tx.createdAt.toLocal()}'))),
              ]))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment(BuildContext context, WidgetRef ref, SubscriptionPlan plan) async {
    try {
      final tx = await ref.read(subscriptionRepositoryProvider).createPaymentIntent(plan.code);
      ref.invalidate(paymentTransactionsProvider);
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('${plan.name} payment request'),
        content: Text('Payment request created for KSh ${plan.price.toStringAsFixed(0)}.\n\nPay via M-Pesa Till 1658309, then provide the M-Pesa transaction reference for verification. Your subscription will only become active after server-side payment verification.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done'))],
      ));
      debugPrint('InvoiceEasy payment intent: ${tx.id}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start payment: $e')));
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.subscription});
  final Subscription? subscription;
  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final status = sub == null ? 'No subscription' : switch (sub.status) {
      SubscriptionStatus.trialing => 'Free trial',
      SubscriptionStatus.active => 'Active',
      SubscriptionStatus.expired => 'Expired',
      SubscriptionStatus.cancelled => 'Cancelled',
      SubscriptionStatus.pastDue => 'Payment due',
      SubscriptionStatus.none => 'No subscription',
    };
    final days = sub?.daysRemaining;
    return Card(child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.surface])), child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.workspace_premium_rounded, color: Theme.of(context).colorScheme.onPrimary)),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(status, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(days == null ? 'Subscription access is controlled securely.' : days == 1 ? '1 day remaining' : '$days days remaining')]))
    ])));
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSubscribe});
  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;
  @override
  Widget build(BuildContext context) {
    final annual = plan.isAnnual;
    return Card(clipBehavior: Clip.antiAlias, child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(border: annual ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (annual) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)), child: Text('BEST VALUE', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.w900))),
      if (annual) const SizedBox(height: 12),
      Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text(plan.description ?? ''),
      const SizedBox(height: 16),
      Text('KSh ${plan.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
      Text(annual ? 'per year • KSh 166.67/month equivalent' : 'per month'),
      if (annual) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Save KSh 400 vs monthly billing', style: TextStyle(fontWeight: FontWeight.w800))),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      ...const ['Unlimited invoices', 'Customers & products', 'Professional PDF invoices', 'Cloud backup & sync', 'Reports & business records'].map((x) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(Icons.check_circle_outline, size: 19), const SizedBox(width: 9), Expanded(child: Text(x))]))),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSubscribe, icon: const Icon(Icons.payments_outlined), label: const Text('Continue to payment')),
    )])));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [const Text('Unable to load plans'), const SizedBox(height: 6), Text(message), const SizedBox(height: 10), OutlinedButton(onPressed: onRetry, child: const Text('Retry'))])));
}
