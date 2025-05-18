import 'dart:convert';

import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';
import 'manage_addresses_screen.dart';
import 'package:cpmad_final/service/UserService.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState  extends State<AccountScreen> {
  final currentUser = CurrentUser().email;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final data = await UserService.fetchUserByEmail(currentUser ?? '');
      setState(() => userInfo = data);
    } catch (e) {
      print('❌ Lỗi lấy user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        backgroundColor: Colors.blueAccent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  isWide
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột trái: Thông tin cá nhân
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildProfileCard(context, userInfo, _loadUserInfo),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Cột phải: Tiện ích
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOptions(context, userInfo),
                          ],
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _buildProfileCard(context, userInfo, _loadUserInfo),
                      const SizedBox(height: 24),
                      _buildOptions(context, userInfo),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
// Profile Card
Widget _buildProfileCard(BuildContext context, Map<String, dynamic>? userInfo, VoidCallback reloadUserInfo) {
  final name = userInfo!['name'] ?? '---';
  final email = userInfo!['email'] ?? '---';
  final role = userInfo!['role'] == 'admin' ? 'Quản trị viên' : 'Khách hàng';
  final status = userInfo!['status'] == 'active' ? 'Hoạt động' : 'Vô hiệu hóa';

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Colors.indigo[50],
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      final base64Image = base64Encode(bytes);
                      print('📤 Ảnh base64 dài: ${base64Image.length}');
                      final success = await UserService.updateAvatar(CurrentUser().email ?? '', base64Image);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ảnh đại diện đã được cập nhật.")),
                        );
                        reloadUserInfo();;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Không thể cập nhật ảnh.")),
                        );
                      }
                    }
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: userInfo['avatar'] != null
                        ? MemoryImage(base64Decode(userInfo['avatar']))
                        : const AssetImage('assets/images/product/acer/aceracer1.png') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          buildInfoRow(
            Icons.location_on,
            'Địa chỉ giao hàng',
            null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAddressesScreen()),
              );
            },
          ),
          buildInfoRow(Icons.person, 'Vai trò', role),
          buildInfoRow(Icons.lock, 'Trạng thái tài khoản', status),
          buildInfoRow(Icons.edit, 'Chỉnh sửa thông tin', null, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          }),
        ],
      ),
    ),
  );
}

// Info Row
Widget buildInfoRow(IconData icon, String title, String? subtitle, {VoidCallback? onTap}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    leading: Icon(icon, color: Colors.blueAccent),
    title: Text(title),
    subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
    trailing: onTap != null
        ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent)
        : null,
    onTap: onTap,
  );
}
// Info Option
Widget _buildOptions(BuildContext context, Map<String, dynamic>? userInfo) {
  final int points = userInfo!['loyalty_point'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Xem lịch sử đơn hàng'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.go('/order-history');
        },
      ),
      const SizedBox(height: 24),
      const Text(
        'Điểm thưởng của bạn',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Card(
        color: Colors.orange[100],
        child: ListTile(
          leading: const Icon(Icons.star, color: Colors.orange),
          title: Text('$points điểm'),
          subtitle: const Text('Tích lũy từ các đơn hàng trước'),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}