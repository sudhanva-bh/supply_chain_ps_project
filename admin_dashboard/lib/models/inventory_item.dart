class InventoryItem {
  final int itemID;
  final String name;
  final int stockQuantity;
  final double unitPrice;
  final int categoryID;
  final int supplierID;

  InventoryItem({
    required this.itemID,
    required this.name,
    required this.stockQuantity,
    required this.unitPrice,
    required this.categoryID,
    required this.supplierID,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      itemID: json['itemID'],
      name: json['name'],
      stockQuantity: json['stockQuantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      categoryID: json['categoryID'],
      supplierID: json['supplierID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemID': itemID,
      'name': name,
      'stockQuantity': stockQuantity,
      'unitPrice': unitPrice,
      'categoryID': categoryID,
      'supplierID': supplierID,
    };
  }
}
