import 'package:flutter/material.dart';

class LineItem {
  String description;
  int quantity;
  double unitPrice;
  double total;

  // Controllers for form input
  TextEditingController descriptionController;
  TextEditingController quantityController;
  TextEditingController unitPriceController;

  LineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    TextEditingController? descriptionController,
    TextEditingController? quantityController,
    TextEditingController? unitPriceController,
  }) : descriptionController =
           descriptionController ?? TextEditingController(text: description),
       quantityController =
           quantityController ??
           TextEditingController(text: quantity.toString()),
       unitPriceController =
           unitPriceController ??
           TextEditingController(text: unitPrice.toStringAsFixed(2));

  /// ✅ Factory to deserialize from JSON
  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  /// ✅ Method to convert LineItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}
