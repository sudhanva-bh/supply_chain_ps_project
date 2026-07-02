class Supplier {
  final int supplierID;
  final String companyName;
  final String contactEmail;
  final String region;

  Supplier({
    required this.supplierID,
    required this.companyName,
    required this.contactEmail,
    required this.region,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierID: json['supplierID'],
      companyName: json['companyName'],
      contactEmail: json['contactEmail'],
      region: json['region'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierID': supplierID,
      'companyName': companyName,
      'contactEmail': contactEmail,
      'region': region,
    };
  }
}
