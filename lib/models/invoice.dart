import 'line_item.dart'; // Assuming you have a `LineItem` model to represent items in an invoice

class Invoice {
  final String id;
  final String clientName;
  final String invoiceNumber;
  final DateTime date;
  final List<LineItem> lineItems; // Changed to List<LineItem> instead of List<String>
  final double totalAmount;

  Invoice({
    required this.id,
    required this.clientName,
    required this.invoiceNumber,
    required this.date,
    required this.lineItems,
    required this.totalAmount,
  });

  // Convert from JSON (e.g., when loading from SharedPreferences)
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      clientName: json['clientName'],
      invoiceNumber: json['invoiceNumber'],
      date: DateTime.parse(json['date']),
      lineItems: (json['lineItems'] as List)
          .map((item) => LineItem.fromJson(item)) // Convert each item to LineItem
          .toList(),
      totalAmount: json['totalAmount'],
    );
  }

  get items => null;

  // Convert to JSON (e.g., when saving to SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(), // Serialize LineItem objects
      'totalAmount': totalAmount,
    };
  }
}
