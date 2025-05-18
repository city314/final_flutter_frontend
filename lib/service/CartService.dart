import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pattern/current_user.dart';

class CartService {
  static const String baseUrl = 'http://localhost:3003/api/carts';

  static Future<Cart?> fetchCart(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId'));
    if (response.statusCode == 200) {
      return Cart.fromJson(json.decode(response.body));
    }
    return null;
  }

  static Future<Cart> fetchCartById(String cartId) async {
    final uri = Uri.parse('$baseUrl/id/$cartId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không tìm thấy giỏ hàng');
    }
  }

  static Future<bool> removeItem(String userId, String variantId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/remove'),
      body: jsonEncode({"user_id": userId, "variant_id": variantId}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> clearCart(String userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clear/$userId'));
    return response.statusCode == 200;
  }

  /// Tạo mới giỏ hàng (nếu chưa có)
  static Future<void> createCartAndAddItem({
    required String userId,
    required String variantId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$baseUrl/create');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'items': [
          {'variant_id': variantId, 'quantity': quantity}
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final cartId = userId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cartId', cartId);
    } else {
      throw Exception('Tạo giỏ hàng thất bại: ${response.body}');
    }
  }

  /// Thêm sản phẩm vào giỏ hàng đã có
  static Future<void> updateCartItem({
    required String userId,
    required String variantId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$baseUrl/add');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'variant_id': variantId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Cập nhật giỏ hàng thất bại: ${response.body}');
    }
  }

  static Future<bool> isCartCreated() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('guestId');
    return cartId != null && cartId.isNotEmpty;
  }

  static Future<String> getEffectiveUserId() async {
    final prefs = await SharedPreferences.getInstance();

    // Nếu đã đăng nhập → dùng email
    if (CurrentUser().isLogin && CurrentUser().email != null) {
      return CurrentUser().email!;
    }

    // Nếu chưa có guestId → tạo và lưu
    if (!prefs.containsKey('guestId')) {
      final uuid = const Uuid().v4();
      await prefs.setString('guestId', uuid);
      return uuid;
    }

    // Nếu đã có guestId
    return prefs.getString('guestId')!;
  }

  static Future<void> updateCartItemQuantity({
    required String userId,
    required String variantId,
    required int quantity,
  }) async {
    final url = Uri.parse('$baseUrl/update');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'variant_id': variantId,
        'quantity': quantity,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update cart item');
    }
  }

  static Future<void> updateCartUserId(String oldUserId, String newUserId) async {
    final uri = Uri.parse('$baseUrl/update-user');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'old_user_id': oldUserId,
        'new_user_id': newUserId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Cập nhật cart user_id thất bại: ${res.body}');
    }
  }

  static Future<bool> removeItemsFromCart(List<String> variantIds, String userId) async {
    final uri = Uri.parse('$baseUrl/remove-items'); // backend cần hỗ trợ endpoint này
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'variantIds': variantIds, 'user_id': userId}),
    );
    return response.statusCode == 200;
  }

}
