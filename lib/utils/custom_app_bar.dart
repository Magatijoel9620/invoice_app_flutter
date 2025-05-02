import 'package:flutter/material.dart';

PreferredSizeWidget customAppBar(String title, {
  required bool isDarkMode,
  required VoidCallback toggleTheme,
}) {
  return AppBar(
    title: Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 32,
        ),
        const SizedBox(width: 8),
        Text(title),
      ],
    ),
    actions: [
      IconButton(
        icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        onPressed: toggleTheme,
      ),
    ],
  );
}
