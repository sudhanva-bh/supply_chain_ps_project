class PurchaseOrderItem {
  final int orderItemID;
  final int orderID;
  final int itemID;
  final int quantityOrdered;
  final double negotiatedPrice;

  PurchaseOrderItem({
    required this.orderItemID,
    required this.orderID,
    required this.itemID,
    required this.quantityOrdered,
    required this.negotiatedPrice,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      orderItemID: json['orderItemID'],
      orderID: json['orderID'],
      itemID: json['itemID'],
      quantityOrdered: json['quantityOrdered'],
      negotiatedPrice: (json['negotiatedPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderItemID': orderItemID,
      'orderID': orderID,
      'itemID': itemID,
      'quantityOrdered': quantityOrdered,
      'negotiatedPrice': negotiatedPrice,
    };
  }
}
