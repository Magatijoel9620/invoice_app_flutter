import 'line_item.dart'; // Assuming you have a LineItem model

class Invoice {
  final String id;
  final String clientName;
  final String invoiceNumber;
  final DateTime date;
  final List<LineItem> lineItems;
  final double totalAmount;
  final bool isArchived; // <-- ADDED: For tracking archive status

  Invoice({
    required this.id,
    required this.clientName,
    required this.invoiceNumber,
    required this.date,
    required this.lineItems,
    required this.totalAmount,
    this.isArchived = false, // <-- ADDED: Default to false
  });

  // Convert from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      clientName: json['clientName'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      lineItems: (json['lineItems'] as List)
          .map((itemJson) => LineItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(), // Handle num for flexibility
      isArchived: json['isArchived'] as bool? ?? false, // <-- ADDED: Handle potential null and default
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'isArchived': isArchived, // <-- ADDED: Serialize isArchived
    };
  }

  // copyWith method for creating modified copies
  Invoice copyWith({
    String? id,
    String? clientName,
    String? invoiceNumber,
    DateTime? date,
    List<LineItem>? lineItems,
    double? totalAmount,
    bool? isArchived,
  }) {
    return Invoice(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      lineItems: lineItems ?? this.lineItems,
      totalAmount: totalAmount ?? this.totalAmount,
      isArchived: isArchived ?? this.isArchived, // <-- ADDED
    );
  }

  // 'items' getter - you had 'get items => null;'
  // If you intend for 'items' to be an alias for 'lineItems', you can do:
  List<LineItem> get items => lineItems;

// If 'items' was a placeholder and is not needed, you can remove it.
}

