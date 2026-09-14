import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../providers/app_providers.dart';
import 'customer_profile_screen.dart';
import 'widgets/app_card.dart';
import 'widgets/empty_state.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersState();
}

class _CustomersState extends ConsumerState<CustomersScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(customersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Customer'),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(customersProvider),
        ),
        data: (items) {
          final normalized = query.trim().toLowerCase();
          final list = items.where((customer) {
            if (normalized.isEmpty) return true;
            return customer.name.toLowerCase().contains(normalized) ||
                customer.phone.toLowerCase().contains(normalized) ||
                customer.email.toLowerCase().contains(normalized);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customersProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Customers',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Customer profiles, balances and invoice history.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search customers',
                  ),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  EmptyState(
                    icon: normalized.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off_rounded,
                    title: normalized.isEmpty
                        ? 'No customers yet'
                        : 'No matching customers',
                    message: normalized.isEmpty
                        ? 'Add a customer once and reuse them on every invoice.'
                        : 'Try another name, phone or email.',
                    actionLabel: normalized.isEmpty ? 'Add customer' : null,
                    onAction: normalized.isEmpty ? () => _edit(null) : null,
                  )
                else
                  ...list.map(
                    (customer) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerProfileScreen(customer: customer),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                customer.name.isEmpty
                                    ? '?'
                                    : customer.name[0].toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (customer.phone.isNotEmpty)
                                    Text(customer.phone),
                                  if (customer.email.isNotEmpty)
                                    Text(
                                      customer.email,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _edit(customer);
                                if (value == 'delete') _delete(customer);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(Customer? old) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (_) => CustomerFormDialog(initial: old),
    );
    if (result != null && mounted) {
      await ref.read(customersProvider.notifier).upsert(result);
    }
  }

  Future<void> _delete(Customer customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Delete ${customer.name}? Existing invoices will remain stored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(customersProvider.notifier).delete(customer.id);
    }
  }
}

class CustomerFormDialog extends StatefulWidget {
  final Customer? initial;

  const CustomerFormDialog({super.key, this.initial});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController taxId;

  @override
  void initState() {
    super.initState();
    final customer = widget.initial;
    name = TextEditingController(text: customer?.name ?? '');
    phone = TextEditingController(text: customer?.phone ?? '');
    email = TextEditingController(text: customer?.email ?? '');
    address = TextEditingController(text: customer?.address ?? '');
    taxId = TextEditingController(text: customer?.taxId ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    taxId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add customer' : 'Edit customer'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: taxId,
              decoration:
                  const InputDecoration(labelText: 'Tax ID / KRA PIN (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final customerName = name.text.trim();
            if (customerName.isEmpty) return;
            Navigator.pop(
              context,
              Customer(
                id: widget.initial?.id ?? const Uuid().v4(),
                name: customerName,
                phone: phone.text.trim(),
                email: email.text.trim(),
                address: address.text.trim(),
                taxId: taxId.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
