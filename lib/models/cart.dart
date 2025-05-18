class CartItem {
  final String variantId;
  int quantity;

  CartItem({required this.variantId, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    variantId: json['variant_id'],
    quantity: json['quantity'],
  );
}

class Cart {
  final String? userId;
  final List<CartItem> items;

  Cart({this.userId, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    userId: json['user_id'],
    items: (json['items'] as List)
        .map((e) => CartItem.fromJson(e))
        .toList(),
  );
}
