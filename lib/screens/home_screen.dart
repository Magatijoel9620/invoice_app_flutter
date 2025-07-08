import 'package:flutter/material.dart';
import 'invoice_list_screen.dart';
import 'invoice_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  final VoidCallback toggleTheme;
  final bool isDarkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Helper to navigate and pop drawer
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(

      body: Container(
        width: double.infinity,
        height: double.infinity, // Ensure gradient covers full screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isDarkMode
                ? [colorScheme.surface.withOpacity(0.9), colorScheme.surfaceContainerLowest] // More subtle dark gradient
                : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surfaceContainerLowest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align content to start
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05), // Top spacing
                Icon(
                  Icons.receipt_long_rounded,
                  size: 70,
                  color: widget.isDarkMode ? colorScheme.primary : colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to InvoiceEasy',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create and manage your invoices with unparalleled ease and efficiency.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: screenHeight * 0.08), // Spacing before cards
                Wrap(
                  spacing: 16, // Spacing between cards horizontally
                  runSpacing: 16, // Spacing between cards vertically
                  alignment: WrapAlignment.center,
                  children: [
                    _HomeActionCard(
                      icon: Icons.list_alt_outlined,
                      title: 'View Invoices',
                      subtitle: 'Browse & manage existing invoices',
                      backgroundColor: widget.isDarkMode ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
                      iconColor: widget.isDarkMode ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                      onTap: () => _navigateTo(
                        context,
                        InvoiceListScreen(
                          isDarkMode: widget.isDarkMode,
                          toggleTheme: widget.toggleTheme,
                        ),
                      ),
                    ),
                    _HomeActionCard(
                      icon: Icons.note_add_outlined,
                      title: 'New Invoice',
                      subtitle: 'Create a fresh invoice from scratch',
                      backgroundColor: widget.isDarkMode ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer,
                      iconColor: widget.isDarkMode ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                      onTap: () {
                        showModalBottomSheet<bool>( // Specify the return type if InvoiceEntryScreen pops with a result
                          context: context,
                          isScrollControlled: true, // IMPORTANT: Allows the sheet to take up more height, even full screen
                          backgroundColor: Colors.transparent, // Makes the sheet's background transparent to use InvoiceEntryScreen's own background
                          builder: (BuildContext bottomSheetContext) {
                            // You might need to wrap InvoiceEntryScreen in a way that it can control its own height
                            // or provide it with constraints. For a complex screen, often a Padding and a Container
                            // with maxHeight derived from screen height is useful.

                            return DraggableScrollableSheet(
                              initialChildSize: 0.9, // Start at 90% of screen height
                              minChildSize: 0.5,   // Min at 50%
                              maxChildSize: 0.95,  // Max at 95% (avoid covering status bar completely unless intended)
                              expand: false, // Set to true if you want it to be able to expand to full height initially based on content
                              builder: (BuildContext _, ScrollController scrollController) {
                                return Container(
                                  // This container helps in defining shape and clipping behavior if needed
                                  decoration: BoxDecoration(
                                    color: Theme.of(bottomSheetContext).canvasColor, // Use theme's canvas color for the sheet background
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20.0),
                                      topRight: Radius.circular(20.0),
                                    ),
                                  ),
                                  child: ClipRRect( // Clip the content to the rounded corners
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20.0),
                                      topRight: Radius.circular(20.0),
                                    ),
                                    child: InvoiceEntryScreen(
                                      // Pass the scrollController if InvoiceEntryScreen has a primary scroll view
                                      // and you want the sheet dragging to interact with it.
                                      // For example, if InvoiceEntryScreen's root is a ListView/SingleChildScrollView:
                                      // scrollController: scrollController,
                                      isDarkMode: widget.isDarkMode,
                                      toggleTheme: widget.toggleTheme,
                                      // existingInvoice: null, // This is for a new invoice
                                      // Indicate that it's in a bottom sheet so it can adapt its UI if needed (e.g., custom app bar, padding)
                                      isInBottomSheet: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ).then((result) {
                          // This 'then' block will execute when the bottom sheet is dismissed.
                          // 'result' will be the value passed to Navigator.pop(context, result) from InvoiceEntryScreen.
                          if (result == true) {
                            // Invoice was saved, refresh the list on the underlying screen
                            // You'll need to call the appropriate refresh method from your DashboardScreen/MainScreen's state.
                            // For example, if _loadInvoices is in DashboardScreenState:
                            // _dashboardScreenStateKey.currentState?._loadInvoices(); // If using a GlobalKey
                            // Or use a callback / state management solution (Provider, Riverpod, BLoC)
                            print("Invoice saved from bottom sheet, refresh needed!");
                            // Example: If this card is in DashboardScreen, and DashboardScreen has a _loadData method:
                            // widget.onInvoiceSaved?.call(); // If you pass a callback down to HomeActionCard
                          }
                        });
                      },
                    ),

                  ],
                ),
                SizedBox(height: screenHeight * 0.1), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'InvoiceEasy',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountEmail: Text(
              'Your Invoicing Companion',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Padding(
                padding: const EdgeInsets.all(4.0), // Padding around the image
                child: Image.asset(
                  'assets/images/InvoiceEasy_Logo.png',
                  // Ensure this asset path is correct
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.receipt_long,
                    size: 30,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode
                    ? [colorScheme.primary.withAlpha(200), colorScheme.primaryContainer.withAlpha(150)]
                    : [colorScheme.primary, colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            otherAccountsPictures: [
              IconButton(
                icon: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: colorScheme.onPrimary
                ),
                onPressed: widget.toggleTheme,
                tooltip: "Toggle Theme",
              )
            ],
          ),
          _buildDrawerItem(
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () => Navigator.pop(context), // Already on home
            theme: theme,
            isSelected: true, // Example: Highlight if current screen
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.list_alt_outlined,
            text: 'Invoice List',
            onTap: () => _navigateTo(
              context,
              InvoiceListScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
            ),
            theme: theme,
          ),
          _buildDrawerItem(
            icon: Icons.note_add_outlined,
            text: 'New Invoice',
            onTap: () => _navigateTo(
              context,
              InvoiceEntryScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
            ),
            theme: theme,
          ),
          // Add more items like Settings, About, etc.
          // const Divider(height: 1),
          // _buildDrawerItem(icon: Icons.settings_outlined, text: 'Settings', onTap: () {}, theme: theme),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isSelected = false,
  }) {
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      selected: isSelected,
    );
  }
}

// A more detailed action card widget
class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust card width based on screen size for better responsiveness
    double cardWidth = (screenWidth > 600) ? 200 : (screenWidth / 2) - 30; // Two cards per row on smaller screens
    cardWidth = cardWidth.clamp(150.0, 220.0); // Min and max width

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor, // Use provided background color
      clipBehavior: Clip.antiAlias, // Ensures inkwell ripple respects border radius
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        child: Container(
          width: cardWidth,
          height: 170, // Slightly taller for subtitle
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: iconColor), // Use provided icon color
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: iconColor, // Use provided icon color for title too, or a contrasting one
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: iconColor.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
