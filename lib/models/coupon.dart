class Coupon {
  final String? id;
  final String code;
  final num discountAmount;
  final int usageMax;
  final int usageTimes;
  final DateTime timeCreate;

  Coupon({
    this.id,
    required this.code,
    required this.discountAmount,
    required this.usageMax,
    required this.usageTimes,
    required this.timeCreate,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    id: json['_id'] as String?,
    code: json['code'] as String,
    discountAmount: json['discount_amount'] as num,
    usageMax: json['usage_max'] as int,
    usageTimes: json['usage_times'] as int,
    timeCreate: DateTime.parse(json['time_create'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'code': code,
    'discount_amount': discountAmount,
    'usage_max': usageMax,
    'usage_times': usageTimes,
    'time_create': timeCreate.toIso8601String(),
  };
}