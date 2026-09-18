import 'package:flutter/material.dart';
import '../core/guards/subscription_action_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../core/formatters.dart';
import 'widgets/app_card.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final data = ref.watch(productsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(c, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          Text(
            'Products & Services',
            style: Theme.of(
              c,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Build your reusable business catalog.',
            style: TextStyle(color: Theme.of(c).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          data.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppCard(
                  child: Text(
                    'No products or services yet. Add one to speed up invoicing.',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () => _edit(c, ref, x),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    c,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  x.type == ProductType.product
                                      ? Icons.inventory_2_outlined
                                      : Icons.handyman_outlined,
                                  color: Theme.of(c).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      x.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      x.type == ProductType.product
                                          ? 'Product'
                                          : 'Service',
                                      style: Theme.of(c).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                money.format(x.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }

  static Future<void> _edit(
    BuildContext c,
    WidgetRef ref,
    ProductItem? old,
  ) async {
    if (!SubscriptionActionGuard.requireWrite(c, ref)) return;
    final name = TextEditingController(text: old?.name ?? '');
    final price = TextEditingController(text: old?.price.toString() ?? '');
    final result = await showDialog<ProductItem>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(old == null ? 'Add item' : 'Edit item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              c,
              ProductItem(
                id: old?.id ?? const Uuid().v4(),
                name: name.text.trim(),
                price: double.tryParse(price.text) ?? 0,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.name.isNotEmpty) {
      await ref.read(productsProvider.notifier).upsert(result);
    }
  }
}
