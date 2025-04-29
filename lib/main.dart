import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_entry_screen.dart';
import 'screens/invoice_list_screen.dart';


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
      theme: _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      home: MainScreen(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  final bool isDarkMode;
  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
      InvoiceEntryScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme, existingInvoice: null,),
      InvoiceListScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
        ],
      ),
    );
  }
}
