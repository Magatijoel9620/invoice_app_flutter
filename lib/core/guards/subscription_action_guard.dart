import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/subscription_screen.dart';
import '../providers/subscription_providers.dart';

class SubscriptionActionGuard {
  const SubscriptionActionGuard._();

  static bool requireWrite(BuildContext context, WidgetRef ref) {
    final access = ref.read(subscriptionAccessProvider);
    if (access.canWrite) return true;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your trial or subscription has ended. Choose a plan to continue.')));
    return false;
  }
}
