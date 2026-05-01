class CategoryModel {
  final String id;
  final String key;
  final String name;
  final String emoji;
  final int displayOrder;

  CategoryModel({
    required this.id,
    required this.key,
    required this.name,
    required this.emoji,
    required this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        displayOrder: json['display_order'] as int,
      );
}

