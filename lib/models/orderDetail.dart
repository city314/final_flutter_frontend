import 'package:cpmad_final/models/variant.dart';

class OrderDetail {
  final String? id;
  final String orderId;
  final String productId;
  final int quantity;
  final num price;
  Variant? variant;

  OrderDetail({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.variant,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['_id'] as String?,
      orderId: (json['order_id'] ?? '') as String,
      productId: (json['variant_id'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as int,
      price: (json['price'] ?? 0).toDouble(), // đảm bảo luôn là num
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'order_id': orderId,
    'product_id': productId,
    'quantity': quantity,
    'price': price,
  };
}
