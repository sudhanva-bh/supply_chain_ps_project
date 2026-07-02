import 'purchase_order_item.dart';

class PurchaseOrder {
  final int orderID;
  final String orderDate;
  final double totalCost;
  final String deliveryStatus;
  final List<PurchaseOrderItem>? purchaseOrderItems;

  PurchaseOrder({
    required this.orderID,
    required this.orderDate,
    required this.totalCost,
    required this.deliveryStatus,
    this.purchaseOrderItems,
  });

  PurchaseOrder copyWith({
    int? orderID,
    String? orderDate,
    double? totalCost,
    String? deliveryStatus,
    List<PurchaseOrderItem>? purchaseOrderItems,
  }) {
    return PurchaseOrder(
      orderID: orderID ?? this.orderID,
      orderDate: orderDate ?? this.orderDate,
      totalCost: totalCost ?? this.totalCost,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      purchaseOrderItems: purchaseOrderItems ?? this.purchaseOrderItems,
    );
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      orderID: json['orderID'],
      orderDate: json['orderDate'],
      totalCost: (json['totalCost'] as num).toDouble(),
      deliveryStatus: json['deliveryStatus'],
      purchaseOrderItems: json['purchaseOrderItems'] != null 
          ? (json['purchaseOrderItems'] as List).map((i) => PurchaseOrderItem.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'orderID': orderID,
      'orderDate': orderDate,
      'totalCost': totalCost,
      'deliveryStatus': deliveryStatus,
    };
    if (purchaseOrderItems != null) {
      map['purchaseOrderItems'] = purchaseOrderItems!.map((i) => i.toJson()).toList();
    }
    return map;
  }
}
