import 'package:flutter/material.dart';
import 'package:myapp/screens/pdf_settings_screen.dart';
import 'screens/archived_invoices_screen.dart';
import 'theme/theme.dart'; // Assuming AppTheme.darkTheme() and AppTheme.lightTheme() exist
import 'screens/home_screen.dart';
import 'screens/invoice_entry_screen.dart';
import 'screens/invoice_list_screen.dart';
// Import any other screens you might navigate to from the drawer

void main() {
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatefulWidget {
  const InvoiceApp({super.key});

  @override
  State<InvoiceApp> createState() => _InvoiceAppState();
}

class _InvoiceAppState extends State<InvoiceApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InvoiceEasy',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      // routes: { // Optional: for named routes if you use them from drawer
      //   '/settings': (context) => SettingsScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
      // },
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // If the "Add" tab is tapped, and you want to ensure it's always a fresh entry screen,
    // you might not need special handling here if InvoiceEntryScreen itself doesn't persist state
    // across constructions.
    setState(() {
      _selectedIndex = index;
    });
  }

  // Placeholder for your drawer item navigation
  void _navigateToScreen(BuildContext context, String routeName) {
    Navigator.of(context).pop(); // Close the drawer
    // Example: using named routes
    // Navigator.of(context).pushNamed(routeName);

    // Example: direct navigation (if not using named routes for these)
    if (routeName == 'home') {
      _onItemTapped(0); // Switch to home tab
    } else if (routeName == 'new_invoice') {
      _onItemTapped(1); // Switch to new invoice tab
    } else if (routeName == 'invoices_list') {
      _onItemTapped(2); // Switch to invoice list tab
    }
    // Add more conditions for other drawer items, e.g., settings, profile
    // else if (routeName == '/settings') {
    //   Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme)));
    // }
  }

  Widget _buildAppDrawer(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary, // Or use a custom image/gradient
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // You could also put the logo here
                Image.asset(
                  'assets/images/InvoiceEasy_Logo.png', // Ensure this asset exists
                  height: 40,
                  color: colorScheme.onPrimary, // Ensure visibility on primary color
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.receipt_long, size: 40, color: colorScheme.onPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'InvoiceEasy Menu',
                  style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => _navigateToScreen(context, 'home'),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Invoice'),
            onTap: () => _navigateToScreen(context, 'new_invoice'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('View Invoices'),
            onTap: () => _navigateToScreen(context, 'invoices_list'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined), // Or Icons.archive_outlined
            title: const Text('Archived Invoices'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivedInvoicesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              // TODO: Navigate to your SettingsScreen
              Navigator.pop(context); // Close drawer
              // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Settings (Not Implemented)')),
              );
            },
          ),
          // Example: In your main app's drawer or AppBar
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PdfSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            title: Text(widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
            onTap: () {
              Navigator.pop(context); // Close drawer before toggling theme
              widget.toggleTheme();
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final List<Widget> screens = [
      HomeScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
      InvoiceEntryScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
      InvoiceListScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
    ];

    // Determine the title based on the selected screen/tab
    String currentScreenTitle = 'InvoiceEasy'; // Default
    Widget? appBarTitleWidget;

    if (_selectedIndex == 0) { // Home
      currentScreenTitle = 'Dashboard'; // Or keep InvoiceEasy with logo
    } else if (_selectedIndex == 1) { // New Invoice
      currentScreenTitle = 'Create New Invoice';
    } else if (_selectedIndex == 2) { // List Invoices
      currentScreenTitle = 'All Invoices';
    }

    // Common AppBar Title with Logo
    appBarTitleWidget = Row(
      mainAxisSize: MainAxisSize.min, // Important to prevent Row from taking full width if not needed
      children: [
        Image.asset(
          'assets/images/InvoiceEasy_Logo.png',
          height: 40,
          // Optional: Tint for dark mode if the logo doesn't adapt well
          // color: widget.isDarkMode && theme.brightness == Brightness.dark ? Colors.white : null,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.receipt_long, size: 40),
        ),
        const SizedBox(width: 10),
        Text(
        'InvoiceEasy',
        style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        // Ensure color contrasts with AppBar background
        // color: theme.appBarTheme.titleTextStyle?.color ?? (widget.isDarkMode ? Colors.white : Colors.black),
        ),),
      ],
    );


    return Scaffold(
      appBar: AppBar(
        // title: appBarTitleWidget, // Use the Row with logo as title
        title: _selectedIndex == 0 // Show logo only on home, or specific title for other screens
            ? appBarTitleWidget // Logo and potentially "InvoiceEasy" text
            : Text(currentScreenTitle), // Specific titles for other screens
        centerTitle: _selectedIndex != 0, // Center title for non-home screens
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              semanticLabel: widget.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
            ),
            tooltip: widget.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
            onPressed: widget.toggleTheme,
          ),
          // Example: In your main app's drawer or AppBar
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PdfSettingsScreen()),
              );
            },
          ),
        ],
        // backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        // elevation: theme.appBarTheme.elevation ?? 2.0,
      ),
      drawer: _buildAppDrawer(context, theme, colorScheme),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Invoice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}
