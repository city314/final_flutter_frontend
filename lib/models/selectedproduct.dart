import 'variant.dart';

class SelectedProduct {
  final Variant variant;
  int quantity;
  int discount;

  SelectedProduct({
    required this.variant,
    required this.quantity,
    required this.discount,
  });

  Map<String, dynamic> toJson() => {
    'variant': variant.toJson(),
    'quantity': quantity,
    'discount': discount,
  };

  factory SelectedProduct.fromJson(Map<String, dynamic> json) => SelectedProduct(
    variant: Variant.fromJson(json['variant']),
    quantity: json['quantity'],
    discount: json['discount'],
  );
}
