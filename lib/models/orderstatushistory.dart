class OrderStatusHistory {
  final String orderId;
  final String status;
  final DateTime timeUpdate;

  OrderStatusHistory({
    required this.orderId,
    required this.status,
    required this.timeUpdate,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      orderId: json['order_id'],
      status: json['status'],
      timeUpdate: DateTime.parse(json['time_update']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'status': status,
      'time_update': timeUpdate.toIso8601String(),
    };
  }
}
