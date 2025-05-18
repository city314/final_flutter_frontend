import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chatoverview.dart';
import '../models/user.dart';
import 'package:cpmad_final/pattern/current_user.dart';
import 'package:go_router/go_router.dart';

class UserService {
  static const String _url = 'http://localhost:3001/api/users';
  static const String _urlSupport = 'http://localhost:3001/api/customer-support';

  static Future<void> registerUser({
    required String email,
    required String fullName,
    required String password,
    required String address,
  }) async {
    final url = Uri.parse('$_url/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': fullName,
        'password': password,
        'address': {
          'receiver_name': fullName,
          'address': address,
        }
      }),
    );

    if (response.statusCode == 201) {
      print('✅ Đăng ký thành công!');
    } else {
      try {
        final error = jsonDecode(response.body)['message'];
        throw Exception(error);
      } catch (e) {
        throw Exception('Lỗi không xác định từ server (${response.statusCode})');
      }
    }
  }

  static Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final url = Uri.parse('$_url/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('token', data['token']);
        // await prefs.setString('userName', data['user']['name']);

        CurrentUser().update(
          email: data['user']['email'],
          role: data['user']['role'],
          userId: data['user']['id'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!')),
        );

        if (data['user']['role'] == 'admin') {
          context.go('/admin/dashboard');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đăng nhập thất bại')),
        );
      }
    } catch (e) {
      print('Lỗi response body: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi định dạng phản hồi từ server')),
      );
    }
  }

  static Future<String> sendOtpToEmail(String email) async {
    final url = Uri.parse('$_url/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['otp']; // ⬅ trả mã OTP về
    } else {
      final error = jsonDecode(response.body)['message'];
      throw Exception(error);
    }
  }

  static Future<void> resetPassword(String email, String newPassword) async {
    final url = Uri.parse('$_url/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Lỗi khi đổi mật khẩu');
    }
  }

  static Future<Map<String, dynamic>> fetchUserByEmail(String email) async {
    final url = Uri.parse('$_url/profile/$email');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không tìm thấy người dùng');
    }
  }

  static Future<List<Address>> fetchAddresses(String email) async {
    final res = await http.get(Uri.parse('$_url/$email/addresses'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Address.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải địa chỉ');
  }

  static Future<void> addAddress(String email, Address addr) async {
    final res = await http.post(
      Uri.parse('$_url/$email/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(addr.toJson()),
    );
    if (res.statusCode != 200) throw Exception('Lỗi thêm địa chỉ');
  }

  static Future<void> updateAddress(String email, Address addr) async {
    final res = await http.put(
      Uri.parse('$_url/$email/addresses/${addr.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(addr.toJson()),
    );
    if (res.statusCode != 200) throw Exception('Lỗi cập nhật địa chỉ');
  }

  static Future<void> deleteAddress(String email, String addressId) async {
    final res = await http.delete(
      Uri.parse('$_url/$email/addresses/$addressId'),
    );
    if (res.statusCode != 200) throw Exception('Lỗi xoá địa chỉ');
  }

  static Future<void> setDefaultAddress(String email, String addressId) async {
    final res = await http.put(
      Uri.parse('$_url/$email/addresses/$addressId/set-default'),
    );
    if (res.statusCode != 200) throw Exception('Lỗi cập nhật địa chỉ mặc định');
  }

  static Future<void> updateUserProfile({
    required String oldEmail,
    required String name,
    required String newEmail,
  }) async {
    final url = Uri.parse('$_url/update-profile/$oldEmail');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'newEmail': newEmail,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
    }
  }
  static Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$_url'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách người dùng');
    }
  }

  static Future<bool> updateUser(User user) async {
    final response = await http.put(
      Uri.parse('$_url/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': user.name,
        'email': user.email,
        'gender': user.gender,
        'birthday': user.birthday,
        'phone': user.phone,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> updateUserStatus(String email, String newStatus) async {
    final response = await http.patch(
      Uri.parse('$_url/status/$email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );

    return response.statusCode == 200;
  }

  static Future<String?> sendMessage({
    required String userEmail,
    required String text,
    String image = '',
    required bool isUser,
  }) async {
    print(userEmail);
    final response = await http.post(
      Uri.parse('$_urlSupport/support/sendMessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer_email': userEmail,
        'text': text,
        'image': image,
        'isUser': isUser,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['chatId'];
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  static Future<List<ChatOverview>> fetchChats() async {
    final response = await http.get(Uri.parse(_urlSupport));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ChatOverview.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải dữ liệu chat');
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages(String email) async {
    try {
      final res = await http.get(Uri.parse('$_urlSupport/getMessages/$email'));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<dynamic> rawMessages = data['messages'];
        return rawMessages.map<Map<String, dynamic>>((msg) {
          return {
            'text': msg['text'],
            'isUser': msg['isUser'],
            'image': msg['image'],
            'time': DateTime.parse(msg['time']),
          };
        }).toList();
      } else {
        print('Error loading messages: ${res.body}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchUserImage(String email) async {
    final response = await http.get(Uri.parse('$_url/email/$email'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  static Future<int> getLoyaltyPoint(String email) async {
    final uri = Uri.parse('$_url/loyalty-point?email=$email');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['loyalty_point'];
    } else {
      throw Exception('Lỗi khi lấy điểm khách hàng');
    }
  }

  static Future<bool> checkIfEmailExists(String email) async {
    final resp = await http.get(Uri.parse('$_url/check-email/$email'));
    if (resp.statusCode == 200) {
      final jsonData = json.decode(resp.body);
      return jsonData['exists'] ?? false;
    }
    return false;
  }

  static Future<bool> registerGuest(String email, String name, String password, String fullAddress) async {
    final body = json.encode({
      'email': email,
      'name': name,
      'password': password,
      'address': {
        'receiver_name': name,
        'address': fullAddress,
      }
    });

    final resp = await http.post(
      Uri.parse('$_url/register'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return resp.statusCode == 201;
  }

  static Future<bool> updateLoyalty(String email, int change) async {
    final uri = Uri.parse('$_url/loyalty/$email');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'change': change}),
    );
    return response.statusCode == 200;
  }
}
