import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_providers.dart';

class SubscriptionBootstrapGate extends ConsumerWidget {
  const SubscriptionBootstrapGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionBootstrapProvider);

    return switch (state) {
      AsyncLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AsyncError(:final error) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 46),
                const SizedBox(height: 12),
                const Text(
                  'Could not initialize your subscription.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(subscriptionBootstrapProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      AsyncData() => child,
      _ => child,
    };
  }
}
