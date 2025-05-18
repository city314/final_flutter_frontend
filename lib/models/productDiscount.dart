class ProductDiscount {
  final String? id;
  final String productId;
  final int discountPercent;

  ProductDiscount({
    this.id,
    required this.productId,
    required this.discountPercent,
  });

  factory ProductDiscount.fromJson(Map<String, dynamic> json) => ProductDiscount(
    id: json['_id'] as String?,
    productId: json['product_id'] as String,
    discountPercent: (json['discount_percent'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'product_id': productId,
    'discount_percent': discountPercent,
  };
}