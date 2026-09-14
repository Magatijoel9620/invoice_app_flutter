enum ProductType { product, service }

class ProductItem {
  final String id;
  final String name;
  final ProductType type;
  final double price;
  final String unit;
  final bool taxable;
  final DateTime updatedAt;

  ProductItem({
    required this.id,
    required this.name,
    this.type = ProductType.service,
    required this.price,
    this.unit = 'item',
    this.taxable = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime(2000, 1, 1);

  ProductItem copyWith({
    String? id,
    String? name,
    ProductType? type,
    double? price,
    String? unit,
    bool? taxable,
    DateTime? updatedAt,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      taxable: taxable ?? this.taxable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'price': price,
        'unit': unit,
        'taxable': taxable,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString();
    final type = ProductType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => ProductType.service,
    );

    return ProductItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: type,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? 'item',
      taxable: json['taxable'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime(2000, 1, 1),
    );
  }
}
