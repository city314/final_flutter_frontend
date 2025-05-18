class Review {
  final String? id;
  final String? userId;
  final String? userName;
  final String productId;
  final num rating;
  final String comment;
  final DateTime timeCreate;
  final String? avatar;

  Review({
    this.id,
    this.userId,
    this.userName,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.timeCreate,
    this.avatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['_id'] as String?,
    userId: json['user_id'] as String?,
    userName: json['user_name'],
    productId: json['product_id'] as String,
    rating: json['rating'] as num,
    comment: json['comment'] as String,
    timeCreate: DateTime.parse(json['time_create'] as String),
      avatar: json['avatar'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'user_id': userId,
    'user_name': userName,
    'product_id': productId,
    'rating': rating,
    'comment': comment,
    'time_create': timeCreate.toIso8601String(),
    'avatar': avatar,
  };

  Review copyWith({String? avatar}) {
    return Review(
      productId: productId,
      userId: userId,
      userName: userName,
      comment: comment,
      rating: rating,
      timeCreate: timeCreate,
      avatar: avatar ?? this.avatar,
    );
  }
}