class ItemCategory {
  final int categoryID;
  final String categoryName;
  final String description;

  ItemCategory({
    required this.categoryID,
    required this.categoryName,
    required this.description,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      categoryID: json['categoryID'],
      categoryName: json['categoryName'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryID': categoryID,
      'categoryName': categoryName,
      'description': description,
    };
  }
}
