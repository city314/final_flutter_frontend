class Category {
  final String? id;
  final String name;

  Category({
    this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['_id'] as String?,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
      };
}