import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/brand.dart';
import '../models/category.dart';
import 'package:cpmad_final/pattern/current_user.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../models/productDiscount.dart';
import '../models/review.dart';
import '../models/variant.dart';

class ProductService {
  static const String _urlC = 'http://localhost:3002/api/category';
  static const String _urlB = 'http://localhost:3002/api/brands';
  static const String _urlProduct = 'http://localhost:3002/api/products';
  static const String _urlVariants = 'http://localhost:3002/api/variants';
  static const String _urlReviews = 'http://localhost:3002/api/reviews';

  static Future<List<Category>> fetchAllCategory() async {
    final res = await http.get(Uri.parse(_urlC));
    if (res.statusCode == 200) {
      return (json.decode(res.body) as List)
          .map((e) => Category.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load categories');
  }

  static Future<Category> createCategory(String name) async {
    final res = await http.post(
      Uri.parse(_urlC),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (res.statusCode == 200) return Category.fromJson(json.decode(res.body));
    throw Exception(json.decode(res.body)['message'] ?? 'Create failed');
  }

  static Future<Category> updateCategory(String id, String name) async {
    final res = await http.put(
      Uri.parse('$_urlC/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (res.statusCode == 200) return Category.fromJson(json.decode(res.body));
    throw Exception('Update failed');
  }

  static Future<void> deleteCategory(String id) async {
    final res = await http.delete(Uri.parse('$_urlC/$id'));
    if (res.statusCode != 200) {
      final msg = json.decode(res.body)['message'] ?? 'Delete failed';
      throw Exception(msg);
    }
  }

  static Future<List<Brand>> fetchAllBrand() async {
    final res = await http.get(Uri.parse(_urlB));
    if (res.statusCode == 200) {
      return (json.decode(res.body) as List)
          .map((e) => Brand.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load brand');
  }

  static Future<Brand> createBrand(String name) async {
    final res = await http.post(
      Uri.parse(_urlB),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (res.statusCode == 200) return Brand.fromJson(json.decode(res.body));
    throw Exception(json.decode(res.body)['message'] ?? 'Create failed');
  }

  static Future<Brand> updateBrand(String id, String name) async {
    final res = await http.put(
      Uri.parse('$_urlB/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (res.statusCode == 200) return Brand.fromJson(json.decode(res.body));
    throw Exception('Update failed');
  }

  static Future<void> deleteBrand(String id) async {
    final res = await http.delete(Uri.parse('$_urlB/$id'));
    if (res.statusCode != 200) {
      final msg = json.decode(res.body)['message'] ?? 'Delete failed';
      throw Exception(msg);
    }
  }

  static Future<List<Variant>> fetchAllVariants() async {
    final response = await http.get(Uri.parse(_urlVariants));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Variant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<List<Variant>> fetchVariantsByProduct(String productId) async {
    final response = await http.get(Uri.parse('$_urlVariants/by-product/$productId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<Variant> variants = jsonList.map((e) => Variant.fromJson(e)).toList();
      return variants;
    } else {
      throw Exception('Lỗi khi tải danh sách biến thể');
    }
  }

  static Future<Variant> createVariant(Variant v) async {
    final res = await http.post(
      Uri.parse(_urlVariants),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(v.toJson()),
    );
    if (res.statusCode == 201) {
      return Variant.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Tạo variant thất bại');
    }
  }

  static Future<Variant> updateVariant(String id, Variant v) async {
    final res = await http.put(
      Uri.parse('$_urlVariants/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(v.toJson()),
    );
    if (res.statusCode == 200) {
      return Variant.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Cập nhật variant thất bại');
    }
  }

  static Future<void> deleteVariant(String id) async {
    final res = await http.delete(Uri.parse('$_urlVariants/$id'));
    if (res.statusCode != 200) {
      throw Exception('Xoá variant thất bại');
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    final response = await http.get(Uri.parse(_urlProduct));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Product> createProduct(Product p) async {
    final res = await http.post(
      Uri.parse(_urlProduct),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(p.toJson()),
    );
    if (res.statusCode == 201) {
      return Product.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Tạo thất bại');
    }
  }

  static Future<Product> updateProduct(String id, Product p) async {
    final res = await http.put(
      Uri.parse('$_urlProduct/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(p.toJson()),
    );
    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Cập nhật thất bại');
    }
  }

  static Future<void> deleteProduct(String id) async {
    final res = await http.delete(Uri.parse('$_urlProduct/$id'));
    if (res.statusCode != 200) {
      throw Exception('Xoá thất bại');
    }
  }

  static Future<bool> updateDiscounts(List<ProductDiscount> discounts) async {
    final url = Uri.parse('$_urlProduct/discounts/update');

    final body = jsonEncode({
      'discounts': discounts.map((e) => {
        'productId': e.productId,
        'discountPercent': e.discountPercent,
      }).toList()
    });

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) return true;
    print('Update failed: ${response.body}');
    return false;
  }

  Future<Map<String, List<Product>>> fetchProductSummary() async {
    final response = await http.get(Uri.parse('$_urlProduct/summary'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'promotions': (data['promotions'] as List).map((e) => Product.fromJson(e)).toList(),
        'newProducts': (data['newProducts'] as List).map((e) => Product.fromJson(e)).toList(),
        'bestSellers': (data['bestSellers'] as List).map((e) => Product.fromJson(e)).toList(),
      };
    } else {
      throw Exception('Lỗi khi lấy tổng hợp sản phẩm');
    }
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    final response = await http.get(
      Uri.parse('$_urlProduct/by-category?categoryId=$categoryId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products for category $categoryId');
    }
  }

  static Future<List<Product>> fetchProductsPanigation({
    String? categoryId,
    String? brandId,
    String? price,
    String? rating,
    String? sort,
    int skip = 0,
    int limit = 20,
  }) async {
    final query = {
      if (categoryId != null) 'categoryId': categoryId,
      if (brandId != null) 'brandId': brandId,
      if (price != null) 'price': price,
      if (rating != null) 'rating': rating,
      if (sort != null) 'sort': sort,
      'skip': '$skip',
      'limit': '$limit',
    };

    final uri = Uri.parse('$_urlProduct/pagination').replace(queryParameters: query);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Product?> fetchProductById(String productId) async {
    final url = Uri.parse(_urlProduct);
    final res = await http.get(url);

    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);
      final matched = data.firstWhere((e) => e['_id'] == productId, orElse: () => null);
      if (matched != null) {
        return Product.fromJson(matched);
      }
    }

    return null;
  }

  static Future<void> postReview(Review review) async {
    final response = await http.post(
      Uri.parse(_urlReviews),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(review.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to post review');
    }
  }

  static Future<List<Review>> fetchReviews(String productId) async {
    final response = await http.get(Uri.parse('$_urlReviews/$productId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Review.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải đánh giá');
    }
  }

  static Future<bool> updateVariantStock(String variantId, int quantityChange) async {
    final uri = Uri.parse('$_urlVariants/stock/$variantId');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'change': quantityChange}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateProductSold(String productId, int quantityChange) async {
    final uri = Uri.parse('$_urlProduct/sold/$productId');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'change': quantityChange}),
    );
    return response.statusCode == 200;
  }

  static Future<Variant> fetchVariantById(String id) async {
    final response = await http.get(Uri.parse('$_urlVariants/order/$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Nếu backend trả về List (thường là do Mongo hoặc find), lấy phần tử đầu tiên
      if (data is List && data.isNotEmpty) {
        return Variant.fromJson(data.first as Map<String, dynamic>);
      }

      // Nếu là object Map, dùng trực tiếp
      if (data is Map<String, dynamic>) {
        return Variant.fromJson(data);
      }

      throw Exception('Dữ liệu không hợp lệ: $data');
    } else {
      throw Exception('❌ Không tải được variant với id $id');
    }
  }
}