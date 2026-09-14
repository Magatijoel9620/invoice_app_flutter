import 'package:uuid/uuid.dart';

enum InvoiceStatus { draft, sent, viewed, partiallyPaid, paid, overdue, cancelled }
enum PaymentMethod { mpesa, bank, cash, card, other }

String _newId() => const Uuid().v4();

InvoiceStatus _invoiceStatusFromJson(Object? value) {
  final name = value?.toString();
  return InvoiceStatus.values.firstWhere(
    (item) => item.name == name,
    orElse: () => InvoiceStatus.draft,
  );
}

PaymentMethod _paymentMethodFromJson(Object? value) {
  final name = value?.toString();
  return PaymentMethod.values.firstWhere(
    (item) => item.name == name,
    orElse: () => PaymentMethod.other,
  );
}

class InvoiceLine {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final bool taxable;

  const InvoiceLine({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxable = false,
  });

  double get total => quantity * unitPrice;

  InvoiceLine copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    bool? taxable,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxable: taxable ?? this.taxable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxable': taxable,
      };

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['id']?.toString() ?? _newId(),
      description: json['description']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      taxable: json['taxable'] as bool? ?? false,
    );
  }
}

class Payment {
  final String id;
  final DateTime date;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final String note;

  const Payment({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    this.reference = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'method': method.name,
        'reference': reference,
        'note': note,
      };

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? _newId(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: _paymentMethodFromJson(json['method']),
      reference: json['reference']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

class Invoice {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String number;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceLine> lines;
  final InvoiceStatus status;
  final double discount;
  final bool vatEnabled;
  final double vatRate;
  final List<Payment> payments;
  final String notes;
  final bool archived;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.number,
    required this.issueDate,
    required this.dueDate,
    required this.lines,
    this.status = InvoiceStatus.draft,
    this.discount = 0,
    this.vatEnabled = false,
    this.vatRate = 16,
    this.payments = const [],
    this.notes = '',
    this.archived = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime(2000, 1, 1);

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  double get taxableSubtotal => lines
      .where((line) => line.taxable)
      .fold(0, (sum, line) => sum + line.total);

  double tax([double? rate]) {
    if (!vatEnabled) return 0;
    final effectiveRate = rate ?? vatRate;
    return taxableSubtotal * (effectiveRate / 100);
  }

  double total([double? rate]) =>
      (subtotal - discount).clamp(0, double.infinity).toDouble() + tax(rate);

  double get amountPaid => payments.fold(0, (sum, payment) => sum + payment.amount);

  double balance([double? rate]) =>
      (total(rate) - amountPaid).clamp(0, double.infinity).toDouble();

  Invoice copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? number,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLine>? lines,
    InvoiceStatus? status,
    double? discount,
    bool? vatEnabled,
    double? vatRate,
    List<Payment>? payments,
    String? notes,
    bool? archived,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      number: number ?? this.number,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      discount: discount ?? this.discount,
      vatEnabled: vatEnabled ?? this.vatEnabled,
      vatRate: vatRate ?? this.vatRate,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'customerId': customerId,
        'customerName': customerName,
        'number': number,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'lines': lines.map((line) => line.toJson()).toList(),
        'status': status.name,
        'discount': discount,
        'vatEnabled': vatEnabled,
        'vatRate': vatRate,
        'payments': payments.map((payment) => payment.toJson()).toList(),
        'notes': notes,
        'archived': archived,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final rawPayments = json['payments'];

    return Invoice(
      id: json['id']?.toString() ?? _newId(),
      businessId: json['businessId']?.toString() ?? 'default',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      number: json['number']?.toString() ?? '',
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      lines: rawLines is List
          ? rawLines
              .whereType<Map>()
              .map((item) => InvoiceLine.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      status: _invoiceStatusFromJson(json['status']),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      vatEnabled: json['vatEnabled'] as bool? ?? false,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 16,
      payments: rawPayments is List
          ? rawPayments
              .whereType<Map>()
              .map((item) => Payment.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      notes: json['notes']?.toString() ?? '',
      archived: json['archived'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime(2000, 1, 1),
    );
  }
}
