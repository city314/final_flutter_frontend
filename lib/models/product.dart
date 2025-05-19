import 'variant.dart';

class Product {
  final String? id;
  final String name;
  final String categoryId;
  final String brandId;
  final String? categoryName;
  final String? brandName;
  int? variantCount;
  int? lowestPrice;
  final String description;
  final int stock;
  int? discountPercent;
  int? soldCount;
  final List<Map<String, String>> images;
  final DateTime timeAdd;
  final List<Variant> variants;
  final double? averageRating;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.brandId,
    this.categoryName,
    this.brandName,
    this.variantCount,
    this.lowestPrice,
    required this.description,
    required this.stock,
    this.discountPercent,
    this.soldCount,
    required this.images,
    required this.timeAdd,
    this.variants = const [],
    this.averageRating,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] as String?,
    name: json['name'] as String? ?? '',
    categoryId: json['category_id'] as String? ?? '',
    brandId: json['brand_id'] as String? ?? '',
    categoryName: json['categoryName'] ?? '',
    brandName: json['brandName'] ?? '',
    variantCount: json['variantCount'] ?? 0,
    lowestPrice: json['lowest_price'] ?? 0,
    description: json['description'] as String? ?? '',
    stock: json['stock'] as int? ?? 0,
    discountPercent: json['discount_percent'] as int? ?? 0,
    soldCount: json['soldCount'] as int? ?? 0,
    images: List<Map<String, String>>.from(
        (json['images'] as List? ?? []).map((e) => Map<String, String>.from(e))),
    timeAdd: DateTime.tryParse(json['time_create'] as String? ?? '') ?? DateTime.now(),
    variants: (json['variants'] as List<dynamic>?)
        ?.map((e) => Variant.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    averageRating: (json['averageRating'] != null)
        ? (json['averageRating'] as num).toDouble()
        : null,
  );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'brand_id': brandId,
      'description': description,
      'stock': stock,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'averageRating': averageRating,
    };
    if (id != null) m['_id'] = id;
    return m;
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? brandId,
    String? brandName,
    String? categoryName,
    int? lowestPrice,
    String? description,
    int? stock,
    int? discountPercent,
    List<Map<String, String>>? images,
    DateTime? timeAdd,
    String? series,
    List<Variant>? variants,       // ← thêm param cho copyWith
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      discountPercent: discountPercent ?? this.discountPercent,
      images: images ?? this.images,
      timeAdd: timeAdd ?? this.timeAdd,
      variants: variants ?? this.variants,
    );
  }

  /// Named constructor trả về một Product "rỗng" (empty)
  factory Product.empty() {
    return Product(
      id: '',
      name: '',
      categoryId: '',
      brandId: '',
      description: '',
      lowestPrice: 0,
      stock: 0,
      timeAdd: DateTime.now(),
      variants: [],
      images: [],
    );
  }
}