import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/payment_engine_billing_service.dart';

final paymentEngineBillingServiceProvider =
    Provider<PaymentEngineBillingService>((ref) {
      return const PaymentEngineBillingService();
    });
