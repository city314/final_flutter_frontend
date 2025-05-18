import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon.dart';
import '../models/order.dart';
import '../models/orderDetail.dart';
import '../models/variant.dart';

class OrderService {
  static const String baseUrl = 'http://localhost:3003/api/coupons'; // đổi lại IP nếu chạy thật
  static const String _urlOrder = 'http://localhost:3003/api/orders'; // đổi lại IP nếu chạy thật
  static const String _urlOrderDetails = 'http://localhost:3003/api/orderdetails';
  static const String _urlOrderStatus = 'http://localhost:3003/api/order-status';
  static const String _urlCouponUsage = 'http://localhost:3003/api/coupon-usage';
  static const String _urlVariants = 'http://localhost:3002/api/variants';

  /// Lấy danh sách coupon
  static Future<List<Coupon>> fetchAllCoupons() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Coupon.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách coupon');
    }
  }

  /// Thêm coupon mới
  static Future<bool> createCoupon(Coupon coupon) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': coupon.code,
        'discount_amount': coupon.discountAmount, // ✅ Đúng tên backend
        'usage_max': coupon.usageMax,             // ✅ Đúng tên backend
      }),
    );
    if (response.statusCode == 201) return true;

    // In lỗi để debug nếu cần
    print('Create failed: ${response.body}');
    return false;
  }

  /// Sửa coupon
  static Future<bool> updateCoupon(Coupon coupon) async {
    final url = Uri.parse('$baseUrl/${coupon.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': coupon.code,
        'discount_amount': coupon.discountAmount,
        'usage_max': coupon.usageMax,
      }),
    );
    if (response.statusCode == 200) return true;

    print('Update failed: ${response.body}');
    return false;
  }

  /// Xoá coupon
  static Future<bool> deleteCoupon(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }

  static Future<Coupon?> checkCoupon(String code) async {
    final uri = Uri.parse('$baseUrl/check?code=${code.toUpperCase()}');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return Coupon.fromJson(json.decode(resp.body));
    } else {
      return null;
    }
  }

  static Future<String?> createOrder(Map<String, dynamic> payload) async {
    final uri = Uri.parse(_urlOrder);
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['_id']; // hoặc theo response thực tế
    }
    return null;
  }

  static Future<bool> createOrderDetails(List<Map<String, dynamic>> details) async {
    final uri = Uri.parse(_urlOrderDetails);
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(details));
    return resp.statusCode == 200;
  }

  static Future<bool> useCoupon(String code) async {
    final uri = Uri.parse('$baseUrl/use/$code');
    final response = await http.patch(uri);
    return response.statusCode == 200;
  }

  static Future<bool> sendConfirmationEmail({
    required String email,
    required String name,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required double finalAmount,
  }) async {
    final uri = Uri.parse('$_urlOrder/send-confirmation');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'name': name,
        'orderId': orderId,
        'items': items,
        'finalAmount': finalAmount,
      }),
    );
    return resp.statusCode == 200;
  }

  static Future<bool> saveOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final uri = Uri.parse(_urlOrderStatus);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'order_id': orderId,
        'status': status,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> saveCouponUsage({
    required String orderId,
    required String couponCode,
  }) async {
    final uri = Uri.parse(_urlCouponUsage);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'order_id': orderId,
        'coupon_code': couponCode,
      }),
    );
    return response.statusCode == 201;
  }

  /// Lấy tất cả đơn hàng (tương đương fetchOrders) - Dashboard
  static Future<List<Order>> fetchAllOrders() async {
    // Nếu backend của bạn có route GET /api/orders/all thì dùng:
    final uri = Uri.parse('$_urlOrder/all');
    // Nếu backend chỉ có GET /api/orders thì thay thành:
    // final uri = Uri.parse(_urlOrder);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception(
          'Không thể tải danh sách đơn hàng (status: ${response.statusCode})'
      );
    }
  }

  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse(_urlOrder));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch orders');
    }
  }

  static Future<List<OrderDetail>> fetchOrderDetails(String orderId) async {
    final response = await http.get(Uri.parse('$_urlOrderDetails/$orderId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OrderDetail.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final uri = Uri.parse('$_urlOrder/$orderId');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Cập nhật trạng thái thất bại');
    }
  }

  static Future<void> createOrderStatusHistory(String orderId, String status) async {
    final uri = Uri.parse(_urlOrderStatus);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'order_id': orderId, 'status': status}),
    );
    if (response.statusCode != 201) {
      throw Exception('Không thể lưu lịch sử trạng thái');
    }
  }

  static Future<List<String>> fetchOrdersUsedCoupon(String code) async {
    final uri = Uri.parse('$baseUrl/by-coupon/$code');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data.map((e) => e['order_id'])); // chỉ lấy order_id
    } else {
      throw Exception('Lỗi khi lấy danh sách đơn hàng đã dùng mã $code');
    }
  }

  Future<List<Order>> fetchUserOrders(String userId) async {
    final response = await http.get(Uri.parse('$_urlOrder/user/$userId'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch user orders');
    }
  }

  Future<List<Order>> getOrdersWithVariants(String userId) async {
    // 1. Gọi đơn hàng
    final ordersRes = await http.get(Uri.parse('$_urlOrder/user/$userId'));
    if (ordersRes.statusCode != 200) throw Exception('Lỗi lấy đơn hàng');
    final ordersJson = json.decode(ordersRes.body) as List;
    final orders = ordersJson.map((e) => Order.fromJson(e)).toList();

    // 2. Lấy tất cả variant_id duy nhất
    final allVariantIds = orders
        .expand((o) => (o.items ?? []).map((i) => i.productId))
        .toSet()
        .toList();

    // 3. Gọi variant service
    final variantRes = await http.get(
      Uri.parse('$_urlVariants/bulk?ids=${allVariantIds.join(",")}'),
    );
    if (variantRes.statusCode != 200) throw Exception('Lỗi lấy variant');
    final variantJson = json.decode(variantRes.body) as List;
    final variantMap = {
      for (var v in variantJson) v['_id']: Variant.fromJson(v)
    };

    // 4. Gán vào từng orderItem
    for (var order in orders) {
      for (var item in order.items ?? []) {
        item.variant = variantMap[item.productId];
      }
    }

    return orders;
  }

  Future<Order> fetchOrderById(String orderId) async {
    final res = await http.get(Uri.parse('$_urlOrder/$orderId'));
    if (res.statusCode != 200) {
      throw Exception('Không thể lấy dữ liệu đơn hàng');
    }

    final jsonData = jsonDecode(res.body);
    final order = Order.fromJson(jsonData);

    // Lấy danh sách variant_id từ items
    final variantIds = order.items?.map((e) => e.productId).toSet().toList();

    // Gọi API lấy thông tin các variant
    final variantRes = await http.get(
      Uri.parse('$_urlVariants/bulk?ids=${variantIds?.join(",")}'),
    );
    if (variantRes.statusCode == 200) {
      final variantJson = jsonDecode(variantRes.body) as List;
      final variantMap = {
        for (var v in variantJson) v['_id']: Variant.fromJson(v),
      };

      // Gán variant vào từng item
      for (var item in order.items ?? []) {
        item.variant = variantMap[item.productId];
      }
    }

    return order;
  }
}
