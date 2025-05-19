import 'package:cpmad_final/models/orderDetail.dart';

import 'orderstatushistory.dart';

enum OrderStatus { pending, complete, canceled, shipped, paid }

class Order {
  final String id;
  final String userId;
  final double totalPrice;
  final double loyaltyPointUsed;
  final double discount;
  final double coupon;
  final double tax;
  final double shippingFee;
  final double finalPrice;
  final double? profit;
  final OrderStatus status;
  final DateTime timeCreate;
  List<OrderDetail>? items;
  final List<OrderStatusHistory>? history;

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.loyaltyPointUsed,
    required this.discount,
    required this.coupon,
    required this.tax,
    required this.shippingFee,
    required this.finalPrice,
    this.profit,
    required this.status,
    required this.timeCreate,
    this.items,
    this.history,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      loyaltyPointUsed: (json['loyalty_point_used'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      coupon: (json['coupon'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shippingFee: (json['shipping_fee'] ?? 0).toDouble(),
      finalPrice: (json['final_price'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      timeCreate: DateTime.tryParse(json['time_create'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List?)?.map((e) => OrderDetail.fromJson(e)).toList() ?? [],
      history: (json['history'] as List?)?.map((e) => OrderStatusHistory.fromJson(e)).toList() ?? [],
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'paid':
        return OrderStatus.paid;
      case 'shipped':
        return OrderStatus.shipped;
      case 'complete':
        return OrderStatus.complete;
      case 'canceled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'user_id': userId,
    'total_price': totalPrice,
    'loyalty_point_used': loyaltyPointUsed,
    'discount': discount,
    'coupon': coupon,
    'tax': tax,
    'shipping_fee': shippingFee,
    'final_price': finalPrice,
    'status': status.name,
    'time_create': timeCreate.toIso8601String(),
  };

  Order copyWith({ OrderStatus? status }) {
    return Order(
      id: this.id,
      userId: this.userId,
      totalPrice: this.totalPrice,
      loyaltyPointUsed: this.loyaltyPointUsed,
      discount: this.discount,
      coupon: this.coupon,
      tax: this.tax,
      shippingFee: this.shippingFee,
      finalPrice: this.finalPrice,
      status: status ?? this.status,
      timeCreate: this.timeCreate,
    );
  }

}
