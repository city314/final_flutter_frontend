class LoyaltyPoint {
  final String? id;
  final String userId;
  final int points;
  final DateTime timeCreate;

  LoyaltyPoint({
    this.id,
    required this.userId,
    required this.points,
    required this.timeCreate,
  });

  factory LoyaltyPoint.fromJson(Map<String, dynamic> json) => LoyaltyPoint(
    id: json['_id'] as String?,
    userId: json['user_id'] as String,
    points: json['points'] as int,
    timeCreate: DateTime.parse(json['time_create'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'user_id': userId,
    'points': points,
    'time_create': timeCreate.toIso8601String(),
  };
}