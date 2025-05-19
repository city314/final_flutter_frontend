// lib/models/variant.dart

import 'dart:convert';

/// Model cho Variant
class Variant {
  final String? id;
  final String productId;
  final String variantName;
  final String color;
  final String attributes;
  final double importPrice;
  final double sellingPrice;
  final int stock;
  final List<Map<String, String>> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Variant({
    this.id,
    required this.productId,
    required this.variantName,
    this.color = 'black',
    required this.attributes,
    required this.importPrice,
    required this.sellingPrice,
    required this.stock,
    this.images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['_id'] as String?,
      productId: json['product_id'] as String,
      variantName: json['variant_name'] as String,
      color: json['color'] as String? ?? 'black',
      attributes: json['attributes'] as String,
      importPrice: (json['import_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      stock: json['stock'] as int,
      images: List<Map<String, String>>.from(
          (json['images'] as List).map((e) => Map<String, String>.from(e))),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'product_id': productId,
      'variant_name': variantName,
      'color': color,
      'attributes': attributes,
      'import_price': importPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'images': images,
    };
    if (id != null) data['_id'] = id;
    data['createdAt'] = createdAt.toIso8601String();
    data['updatedAt'] = updatedAt.toIso8601String();
    return data;
  }

  Variant copyWith({
    String? id,
    String? productId,
    String? variantName,
    String? color,
    String? attributes,
    double? importPrice,
    double? sellingPrice,
    int? stock,
    List<Map<String, String>>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Variant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      color: color ?? this.color,
      attributes: attributes ?? this.attributes,
      importPrice: importPrice ?? this.importPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Variant.empty() => Variant(
    id: '',
    productId: '',
    variantName: '',
    color: '',
    attributes: '',
    importPrice: 0,
    sellingPrice: 0,
    stock: 0,
    images: [],
  );

  @override
  String toString() => jsonEncode(toJson());
}