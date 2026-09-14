import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/invoice_status.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../providers/app_providers.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'widgets/app_card.dart';

class CustomerProfileScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = (ref.watch(invoicesProvider).valueOrNull ?? <Invoice>[])
        .where((invoice) =>
            invoice.customerId == customer.id && !invoice.archived)
        .toList();

    final invoiced = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.total(invoice.vatRate),
    );
    final paid = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.amountPaid,
    );
    final balance = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.balance(invoice.vatRate),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Customer profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    customer.name.isEmpty
                        ? '?'
                        : customer.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (customer.phone.isNotEmpty) Text(customer.phone),
                      if (customer.email.isNotEmpty)
                        Text(
                          customer.email,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      if (customer.address.isNotEmpty)
                        Text(customer.address),
                      if (customer.taxId.isNotEmpty)
                        Text('Tax ID: ${customer.taxId}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metric(context, 'Invoiced', money.format(invoiced)),
              ),
              const SizedBox(width: 10),
              Expanded(child: _metric(context, 'Paid', money.format(paid))),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(context, 'Balance', money.format(balance)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreateInvoiceScreen(preselectedCustomerId: customer.id),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create invoice'),
          ),
          const SizedBox(height: 22),
          Text(
            'Invoice history',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (invoices.isEmpty)
            AppCard(
              child: Text(
                'No invoices for this customer yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...invoices.map(
              (invoice) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: AppCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvoiceDetailsScreen(invoiceId: invoice.id),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(shortDate.format(invoice.issueDate)),
                            Text(
                              invoiceStatusLabel(
                                effectiveInvoiceStatus(
                                  invoice,
                                  invoice.vatRate,
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money.format(invoice.total(invoice.vatRate)),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
