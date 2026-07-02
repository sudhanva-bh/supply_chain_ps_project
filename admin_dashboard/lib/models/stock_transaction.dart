class StockTransaction {
  final int transactionID;
  final int itemID;
  final int quantityChanged;
  final String transactionType;
  final String timestamp;

  StockTransaction({
    required this.transactionID,
    required this.itemID,
    required this.quantityChanged,
    required this.transactionType,
    required this.timestamp,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      transactionID: json['transactionID'],
      itemID: json['itemID'],
      quantityChanged: json['quantityChanged'],
      transactionType: json['transactionType'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionID': transactionID,
      'itemID': itemID,
      'quantityChanged': quantityChanged,
      'transactionType': transactionType,
      'timestamp': timestamp,
    };
  }
}
