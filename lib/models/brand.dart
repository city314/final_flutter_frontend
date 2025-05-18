class Brand {
  final String? id;
  final String name;

  Brand({
    this.id,
    required this.name,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['_id'] as String?,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
      };
} 