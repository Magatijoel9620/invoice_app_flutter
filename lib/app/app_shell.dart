import 'package:flutter/material.dart';
import 'package:invoice_easy/screens/subscription_screen.dart';
import '../screens/archived_invoices_screen.dart';
import '../screens/business_settings_screen.dart';
import '../screens/create_invoice_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoice_list_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/sync_status_banner.dart';
import '../core/widgets/subscription_banner.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onThemeModeChanged});
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final titles = ['Dashboard', 'Invoices', 'Customers', 'Products & Services'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onCreateInvoice: _create),
      InvoiceListScreen(onCreate: _create),
      const CustomersScreen(),
      const ProductsScreen(),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
       actions: [
  IconButton(
    tooltip: isDark ? 'Use light mode' : 'Use dark mode',
    onPressed: () => widget.onThemeModeChanged(
      isDark ? ThemeMode.light : ThemeMode.dark,
    ),
    icon: Icon(
      isDark
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined,
    ),
  ),

  IconButton(
    tooltip: 'Subscription',
    onPressed: () => _open(const SubscriptionScreen()),
    icon: const Icon(Icons.workspace_premium_outlined),
  ),

  if (index == 0)
    IconButton(
      tooltip: 'Reports',
      onPressed: () => _open(const ReportsScreen()),
      icon: const Icon(Icons.insights_outlined),
    ),

  PopupMenuButton<String>(
    onSelected: (v) {
      if (v == 'reports') {
        _open(const ReportsScreen());
      }
      if (v == 'archive') {
        _open(const ArchivedInvoicesScreen());
      }
      if (v == 'settings') {
        _open(const BusinessSettingsScreen());
      }
      if (v == 'account') {
        _open(const AccountScreen());
      }
      if (v == 'subscription') {
        _open(const SubscriptionScreen());
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'reports',
        child: ListTile(
          leading: Icon(Icons.insights_outlined),
          title: Text('Reports'),
        ),
      ),
      PopupMenuItem(
        value: 'archive',
        child: ListTile(
          leading: Icon(Icons.archive_outlined),
          title: Text('Archived invoices'),
        ),
      ),
      PopupMenuItem(
        value: 'settings',
        child: ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('Business settings'),
        ),
      ),
      PopupMenuItem(
        value: 'subscription',
        child: ListTile(
          leading: Icon(Icons.workspace_premium_outlined),
          title: Text('Subscription'),
        ),
      ),
      PopupMenuItem(
        value: 'account',
        child: ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Account'),
        ),
      ),
    ],
  ),
],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          const SubscriptionBanner(),
          Expanded(child: pages[index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Catalog',
          ),
        ],
      ),
      floatingActionButton: index == 0 || index == 1
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Invoice'),
            )
          : null,
    );
  }

  void _create() {
    // The create screen performs the final subscription check before saving.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
