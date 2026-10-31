import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      'Dashboard',
      Icons.grid_view_rounded,
      Icons.grid_view_outlined,
    ),
    _ShellDestination(
      'Invoices',
      Icons.receipt_long_rounded,
      Icons.receipt_long_outlined,
    ),
    _ShellDestination(
      'Customers',
      Icons.people_rounded,
      Icons.people_outline_rounded,
    ),
    _ShellDestination(
      'Catalog',
      Icons.inventory_2_rounded,
      Icons.inventory_2_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onCreateInvoice: _create),
      InvoiceListScreen(onCreate: _create),
      const CustomersScreen(),
      const ProductsScreen(),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 760;
    final isDesktop = width >= 1180;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            if (isCompact) ...[
              Image.asset(
                'assets/images/InvoiceEasy_Mark.png',
                width: 27,
                height: 27,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(titles[index], overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Use light mode' : 'Use dark mode',
            onPressed: () => widget.onThemeModeChanged(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
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
            tooltip: 'More options',
            onSelected: (v) {
              if (v == 'reports') _open(const ReportsScreen());
              if (v == 'archive') _open(const ArchivedInvoicesScreen());
              if (v == 'settings') _open(const BusinessSettingsScreen());
              if (v == 'account') _open(const AccountScreen());
              if (v == 'subscription') _open(const SubscriptionScreen());
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          const SubscriptionBanner(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                final page = _pageFrame(pages[index]);
                if (isDesktop) {
                  return Row(
                    children: [
                      _DesktopSidebar(
                        selectedIndex: index,
                        onSelect: _select,
                        onCreate: _create,
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: page),
                    ],
                  );
                }
                if (!isCompact) {
                  return Row(
                    children: [
                      NavigationRail(
                        selectedIndex: index,
                        onDestinationSelected: _select,
                        labelType: NavigationRailLabelType.all,
                        minWidth: 78,
                        leading: Padding(
                          padding: const EdgeInsets.only(bottom: 18, top: 8),
                          child: IconButton.filledTonal(
                            tooltip: 'Create invoice',
                            onPressed: _create,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                        destinations: _destinations
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.unselectedIcon),
                                selectedIcon: Icon(item.selectedIcon),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: page),
                    ],
                  );
                }
                return page;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _select,
              destinations: _destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.unselectedIcon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label == 'Dashboard' ? 'Home' : item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
      floatingActionButton: isCompact && (index == 0 || index == 1)
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Invoice'),
            )
          : null,
    );
  }

  Widget _pageFrame(Widget page) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: SizedBox.expand(key: ValueKey(index), child: page),
        ),
      ),
    ),
  );

  void _select(int value) {
    if (value == index) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => index = value);
  }

  void _create() {
    // The create screen performs the final subscription check before saving.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );
  }

  void _open(Widget page) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _responsiveRoute(page)),
  );

  Widget _responsiveRoute(Widget page) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: SizedBox.expand(child: page),
      ),
    ),
  );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreate,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  static const _items = <_ShellDestination>[
    _ShellDestination(
      'Dashboard',
      Icons.grid_view_rounded,
      Icons.grid_view_outlined,
    ),
    _ShellDestination(
      'Invoices',
      Icons.receipt_long_rounded,
      Icons.receipt_long_outlined,
    ),
    _ShellDestination(
      'Customers',
      Icons.people_rounded,
      Icons.people_outline_rounded,
    ),
    _ShellDestination(
      'Products & Services',
      Icons.inventory_2_rounded,
      Icons.inventory_2_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 248,
      child: ColoredBox(
        color: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/InvoiceEasy_Mark.png',
                    width: 37,
                    height: 37,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.receipt_long_rounded,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'InvoiceEasy',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                        ),
                        Text(
                          'BUSINESS WORKSPACE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'WORKSPACE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Material(
                    color: selected
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? item.selectedIcon
                                  : item.unselectedIcon,
                              size: 20,
                              color: selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: selected
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurface,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create invoice'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: scheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Your business, clearly organised.',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.selectedIcon, this.unselectedIcon);
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
}
