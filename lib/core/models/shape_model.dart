class ShapeModel {
  final String id;
  final String shapeKey;
  final bool isPremium;
  final DateTime createdAt;

  const ShapeModel({
    required this.id,
    required this.shapeKey,
    this.isPremium = false,
    required this.createdAt,
  });

  factory ShapeModel.fromJson(Map<String, dynamic> json) {
    return ShapeModel(
      id: json['id'] as String,
      shapeKey: json['shape_key'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape_key': shapeKey,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
