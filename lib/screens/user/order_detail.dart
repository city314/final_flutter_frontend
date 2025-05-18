import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../models/order.dart';
import '../../service/OrderService.dart';
import 'CustomNavbar.dart';
import '../../utils/format_utils.dart';
import 'dart:convert';

class OrderDetail extends StatefulWidget {
  final String orderId;
  const OrderDetail({super.key, required this.orderId});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  late Future<Order> _futureOrder;

  @override
  void initState() {
    super.initState();
    _futureOrder = OrderService().fetchOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return FutureBuilder<Order>(
      future: _futureOrder,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Lỗi: ${snapshot.error}')));
        }

        final order = snapshot.data!;

        return Scaffold(
          appBar: CustomNavbar(
            cartItemCount: 0,
            onHomeTap: () {},
            onCategoriesTap: () {},
            onCartTap: () {},
            onRegisterTap: () {},
            onLoginTap: () {},
            onSupportTap: () {},
            onSearch: (value) {},
          ),
          drawer: isAndroid
              ? null
              : Drawer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildMenuItem(Icons.home, 'Trang chủ', false, () {}),
                _buildMenuItem(Icons.history, 'Lịch sử mua hàng', false, () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(Icons.person, 'Tài khoản của bạn', false, () {}),
                _buildMenuItem(Icons.support_agent, 'Hỗ trợ', false, () {}),
                _buildMenuItem(Icons.logout, 'Đăng xuất', false, () {}),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 20),
                    const SizedBox(width: 8),
                    Text('Mã đơn hàng: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _parseStatus(order.status),
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Ngày đặt: ${formatDateTime(order.timeCreate)}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                ...?order.items?.map((item) {
                  final imageBase64 = item.variant?.images.isNotEmpty == true ? item.variant!.images.first['base64'] : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageBase64 != null
                            ? Image.memory(base64Decode(imageBase64), width: 72, height: 72, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 72),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.variant?.variantName ?? 'Không có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Số lượng: ${item.quantity}'),
                            ],
                          ),
                        ),
                        Text(
                          formatPrice(item.price.toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        )
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Text('Tiến trình đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: order.history!.map((step) {
                    return Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(height: 4),
                        Text(step.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(formatDateTime(step.timeUpdate), style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                const Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildPayRow('Tổng tiền sản phẩm:', order.totalPrice),
                _buildPayRow('Giảm giá:', -order.discount),
                _buildPayRow('Phí vận chuyển:', order.shippingFee == 0 ? 'Miễn phí' : order.shippingFee),
                _buildPayRow('Phải thanh toán:', order.finalPrice, bold: true),
              ],
            ),
          ),
        );
      },
    );
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

  String formatDateTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}/${time.year}';
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

  Widget _buildPayRow(String label, dynamic value, {bool bold = false, bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          value is int || value is double
              ? Text(
            formatPrice((value as num).toDouble()),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: green ? Colors.green : Colors.black,
              fontSize: bold ? 16 : 14,
            ),
          )
              : Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: green ? Colors.green : Colors.black,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}