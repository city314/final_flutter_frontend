class CouponUsageOrder {
  final String? id;
  final String orderId;
  final String couponId;
  final DateTime timeUsed;

  CouponUsageOrder({
    this.id,
    required this.orderId,
    required this.couponId,
    required this.timeUsed,
  });

  factory CouponUsageOrder.fromJson(Map<String, dynamic> json) => CouponUsageOrder(
    id: json['_id'] as String?,
    orderId: json['order_id'] as String,
    couponId: json['coupon_id'] as String,
    timeUsed: DateTime.parse(json['time_used'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'order_id': orderId,
    'coupon_id': couponId,
    'time_used': timeUsed.toIso8601String(),
  };
}