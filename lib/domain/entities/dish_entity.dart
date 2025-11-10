class DishEntity {
  final String id;
  final String userId;
  final String name;
  final List<String> ingredients;
  final String imageUrl;
  final String? imageLocalPath;
  final DateTime createdAt;
  final String? description;

  DishEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.ingredients,
    required this.imageUrl,
    this.imageLocalPath,
    required this.createdAt,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'ingredients': ingredients,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory DishEntity.fromJson(Map<String, dynamic> json) {
    return DishEntity(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      description: json['description'],
    );
  }

  DishEntity copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? ingredients,
    String? imageUrl,
    String? imageLocalPath,
    DateTime? createdAt,
    String? description,
  }) {
    return DishEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }
}
