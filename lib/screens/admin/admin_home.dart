import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'admin_bottom_navbar.dart';
import 'admin_brand.dart';
import 'admin_category.dart';
import 'admin_chat.dart';
import 'admin_coupon.dart';
import 'admin_dashboard.dart';
import 'admin_discount.dart';
import 'admin_order.dart';
import 'admin_product.dart';
import 'admin_support.dart';
import 'admin_top_navbar.dart';
import 'admin_user.dart';

class AdminHome extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userAvatarUrl;

  const AdminHome({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userAvatarUrl,
  }) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  // Đặt tiêu đề AppBar cho từng tab (dùng trên mobile)
  final List<String> _titles = [
    'Dashboard',
    'Product Management',
    'Category Management'
    'Brand Management'
    'User Management',
    'Order Management',
    'Coupon Management',
    'Discount Management',
    'Customer Support',
  ];

  @override
  Widget build(BuildContext context) {
    final email = CurrentUser().email ?? '';
    final isMobile = MediaQuery
        .of(context)
        .size
        .width < 800;

    // Danh sách “body” cho từng tab
    final pages = <Widget>[
      const AdminDashboardScreen(),
      const AdminProductScreen(),
      const AdminCategoryScreen(),
      const AdminBrandScreen(),
      const AdminUserScreen(),
      const AdminOrderScreen(),
      const AdminCouponScreen(),
      const AdminDiscountScreen(),
      const SupportScreen(),
      // TODO: thêm các màn khác ở đây
    ];

    return Scaffold(
      // Trên web ta dùng sidebar, trên mobile mới dùng AppBar
      appBar: isMobile
          ? AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          Row(
            children: [
              Text(widget.userName, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.userAvatarUrl),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      )
          : null,

      // Nội dung chính
      body: isMobile
          ? pages[_currentIndex]
          : Row(
        children: [
          AdminTopNavbar(
            selectedIndex: _currentIndex,
            onItemSelected: (i) => setState(() => _currentIndex = i),
            userAvatarUrl: widget.userAvatarUrl,
            userName: widget.userName,
            userRole: widget.userRole,
          ),
          Expanded(child: pages[_currentIndex]),
        ],
      ),

      // Bottom navbar chỉ trên mobile
      bottomNavigationBar: isMobile
          ? AnimatedBottomNavBar(
        onItemSelected: (i) => setState(() => _currentIndex = i),
      )
          : null,
    );
  }
}