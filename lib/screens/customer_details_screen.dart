import 'package:flutter/material.dart';

import '../models/customer.dart';
import 'customer_profile_screen.dart';

/// Backwards-compatible entry point for older routes/imports.
/// The app now uses [CustomerProfileScreen] as the canonical customer detail UI.
class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return CustomerProfileScreen(customer: customer);
  }
}
