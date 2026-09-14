import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool processing = false;

  Future<void> _subscribe(String plan, int amount) async {
    setState(() => processing = true);

    try {
      // Payment integration will be connected here.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$plan selected — payment of KSh $amount will be processed.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your plan',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock more powerful invoicing features as your business grows.',
                    style: theme.textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  _CurrentPlanCard(),

                  const SizedBox(height: 32),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 800;

                      final cards = [
                        _PlanCard(
                          name: 'Free',
                          price: '0',
                          description: 'For getting started',
                          features: const [
                            'Up to 10 invoices',
                            'Customer management',
                            'Basic invoice PDF',
                            'Local data',
                          ],
                          buttonText: 'Current plan',
                          enabled: false,
                          onPressed: null,
                        ),
                        _PlanCard(
                          name: 'Starter',
                          price: '500',
                          description: 'For growing businesses',
                          features: const [
                            'Unlimited invoices',
                            'Cloud backup & sync',
                            'Professional PDF invoices',
                            'Customer history',
                            'Reports',
                          ],
                          buttonText: 'Upgrade',
                          onPressed: processing
                              ? null
                              : () => _subscribe('Starter', 500),
                        ),
                        _PlanCard(
                          name: 'Business',
                          price: '1,000',
                          description: 'For active businesses',
                          highlighted: true,
                          features: const [
                            'Everything in Starter',
                            'Online invoices',
                            'Payment links',
                            'Advanced reports',
                            'Priority features',
                          ],
                          buttonText: 'Upgrade',
                          onPressed: processing
                              ? null
                              : () => _subscribe('Business', 1000),
                        ),
                      ];

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: cards
                              .map(
                                (card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: card,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  _PaymentInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current plan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Free plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text('Active'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onPressed,
    this.highlighted = false,
    this.enabled = true,
  });

  final String name;
  final String price;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool highlighted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: highlighted
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

            if (highlighted) const SizedBox(height: 14),

            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(description),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KSh $price',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (price != '0')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5, left: 5),
                    child: Text('/month'),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 10),

            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled ? onPressed : null,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure payments',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pay securely using M-Pesa. Your subscription is linked to your InvoiceEasy account.',
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