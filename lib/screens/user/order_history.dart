import 'dart:convert';

import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/order.dart';
import '../../service/OrderService.dart';
import 'CustomNavbar.dart';
import '../../utils/format_utils.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang vận chuyển',
    'Đã giao hàng',
    'Đã hủy',
  ];

  // Giả lập trạng thái đăng nhập
  bool isLoggedIn = CurrentUser().isLogin; // Đổi thành false để test trường hợp chưa đăng nhập

  int totalOrders = 0;
  late Future<List<Order>> _futureOrders;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    final userId = CurrentUser().email ?? '';
    _futureOrders = OrderService().getOrdersWithVariants(userId);
    _futureOrders.then((orders) {
      setState(() {
        _orders = orders;
        totalOrders = orders.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      appBar: CustomNavbar(
        onHomeTap: () {},
        onCategoriesTap: () {},
        onCartTap: () {},
        onRegisterTap: () {},
        onLoginTap: () {},
        onSupportTap: () {},
        onSearch: (value) {},
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAndroid)
            Container(
              width: 240,
              color: const Color(0xFFF7F7F7),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMenuItem(Icons.home, 'Trang chủ', false, () {}),
                  _buildMenuItem(Icons.history, 'Lịch sử mua hàng', true, () {}),
                  _buildMenuItem(Icons.person, 'Tài khoản của bạn', false, () {}),
                  _buildMenuItem(Icons.support_agent, 'Hỗ trợ', false, () {}),
                  _buildMenuItem(Icons.logout, 'Đăng xuất', false, () {}),
                ],
              ),
            ),
          // Nội dung bên phải
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề + menu icon cho Android
                  Row(
                    children: [
                      const Text('Lịch sử mua hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      if (isAndroid) ...[
                        Spacer(),
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.home),
                                    title: const Text('Trang chủ'),
                                    onTap: () {},
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.history),
                                    title: const Text('Lịch sử mua hàng'),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text('Tài khoản của bạn'),
                                    onTap: () {},
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.support_agent),
                                    title: const Text('Hỗ trợ'),
                                    onTap: () {},
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.logout),
                                    title: const Text('Đăng xuất'),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tổng số lượng đơn
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('$totalOrders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                            const SizedBox(height: 4),
                            const Text('đơn hàng', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tabs trạng thái đơn hàng
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final bool selected = _selectedTab == index;
                        Color selectedColor;
                        switch (index) {
                          case 0:
                            selectedColor = Colors.blue;
                            break;
                          case 1:
                            selectedColor = Colors.amber;
                            break;
                          case 2:
                            selectedColor = Colors.blue;
                            break;
                          case 3:
                            selectedColor = Colors.amber;
                            break;
                          case 4:
                            selectedColor = Colors.green;
                            break;
                          case 5:
                            selectedColor = Colors.red;
                            break;
                          default:
                            selectedColor = Colors.blue;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: selected,
                            selectedColor: selectedColor,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.grey[200],
                            onSelected: (_) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Danh sách đơn hàng
                  Expanded(
                    child: _orders.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                      itemCount: _filteredOrders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final firstItem = order.items!.isNotEmpty ? order.items?.first : null;
                        final firstImage = firstItem!.variant!.images.isNotEmpty ? firstItem!.variant!.images[0]['base64'] : null;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              firstImage != null
                                  ? Image.memory(base64Decode(firstImage), width: 40, height: 40, fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firstItem?.variant?.variantName ?? 'Sản phẩm ẩn',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatPrice(order.finalPrice),
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Trạng thái: ${_parseStatus(order.status)}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    order.timeCreate.toLocal().toString().split(' ')[0],
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: điều hướng sang trang chi tiết nếu cần
                                      context.goNamed('order-detail', extra: order.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
    );
  }

  List<Order> get _filteredOrders {
    if (_selectedTab == 0) return _orders;

    final statusMapping = {
      1: OrderStatus.pending,
      2: OrderStatus.paid,
      3: OrderStatus.shipped,
      4: OrderStatus.complete,
      5: OrderStatus.canceled,
    };

    final selectedStatus = statusMapping[_selectedTab];
    return _orders.where((o) => o.status == selectedStatus).toList();
  }

  String _parseStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.paid:
        return 'Đã thanh toán';
      case OrderStatus.shipped:
        return 'Đang vận chuyển';
      case OrderStatus.complete:
        return 'Đã giao hàng';
      case OrderStatus.canceled:
        return 'Đã hủy';
      default:
        return 'Không rõ';
    }
  }

  Widget _buildMenuItem(IconData icon, String title, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFFFDECEC) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.red : Colors.black54, size: 22),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.red : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}