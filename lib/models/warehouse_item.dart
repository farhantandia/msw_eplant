class WarehouseItem {
  final String itemNumber;
  final String itemName;
  final String description;
  final String unitType;
  final double availableStock;
  final String? defaultWarehouse;
  final String? defaultLocation;

  WarehouseItem({
    required this.itemNumber,
    required this.itemName,
    this.description = '',
    required this.unitType,
    required this.availableStock,
    this.defaultWarehouse,
    this.defaultLocation,
  });

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      itemNumber: json['itemNumber']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unitType: json['unitType']?.toString() ?? 'PCS',
      availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0.0,
      defaultWarehouse: json['defaultWarehouse']?.toString(),
      defaultLocation: json['defaultLocation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemNumber': itemNumber,
      'itemName': itemName,
      'description': description,
      'unitType': unitType,
      'availableStock': availableStock,
      'defaultWarehouse': defaultWarehouse,
      'defaultLocation': defaultLocation,
    };
  }

  WarehouseItem copyWith({
    String? itemNumber,
    String? itemName,
    String? description,
    String? unitType,
    double? availableStock,
    String? defaultWarehouse,
    String? defaultLocation,
  }) {
    return WarehouseItem(
      itemNumber: itemNumber ?? this.itemNumber,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unitType: unitType ?? this.unitType,
      availableStock: availableStock ?? this.availableStock,
      defaultWarehouse: defaultWarehouse ?? this.defaultWarehouse,
      defaultLocation: defaultLocation ?? this.defaultLocation,
    );
  }
}
