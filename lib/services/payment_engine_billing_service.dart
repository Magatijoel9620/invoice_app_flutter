import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PaymentEngineBillingService {
  const PaymentEngineBillingService();

  SupabaseClient get _client => SupabaseService.client;

  Future<Map<String, dynamic>> call(
    String operation, {
    Map<String, dynamic> payload = const {},
  }) async {
    final response = await _client.functions.invoke(
      'invoiceeasy-billing-bridge',
      body: {'operation': operation, ...payload},
    );
    final data = response.data;
    if (data is! Map) throw StateError('Invalid InvoiceEasy billing response.');
    final map = Map<String, dynamic>.from(data);
    if (map['error'] != null) throw StateError(map['error'].toString());
    return map;
  }

  Future<Map<String, dynamic>> snapshot() => call('snapshot');

  Future<Map<String, dynamic>> createPaymentIntent({
    required String planId,
    required String provider,
    required String idempotencyKey,
    String? phone,
  }) => call(
    'create_intent',
    payload: {
      'plan_id': planId,
      'provider': provider,
      'idempotency_key': idempotencyKey,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    },
  );

  Future<Map<String, dynamic>> startPayment({
    required String paymentIntentId,
    required String provider,
    required String method,
    String? phone,
    String? email,
    String? fullName,
  }) => call(
    'start_payment',
    payload: {
      'payment_intent_id': paymentIntentId,
      'provider': provider,
      'method': method,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
    },
  );

  Future<Map<String, dynamic>> submitManualPayment({
    required String paymentIntentId,
    required String reference,
    String? notes,
  }) => call(
    'submit_manual',
    payload: {
      'payment_intent_id': paymentIntentId,
      'reference': reference.trim().toUpperCase(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    },
  );
}
