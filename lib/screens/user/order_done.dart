// Màn hình hiển thị đặt hàng thành công và chi tiết đơn hàng
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/orderDetail.dart';
import '../../models/selectedproduct.dart';
import '../../utils/format_utils.dart';

class OrderDone extends StatelessWidget {
  final String orderId;
  final DateTime timeCreate;
  final double tax;
  final double discount;
  final double shippingFee;
  final List<SelectedProduct> selectedItems;
  final String receiverName;
  final String phoneNumber;
  final String email;
  final String address;
  final double totalPrice;
  final int loyaltyUsed;
  final double voucherDiscount;
  final bool isVoucherApplied;
  final double finalPrice;

  OrderDone({
    Key? key,
    required this.orderId,
    required this.timeCreate,
    required this.tax,
    required this.discount,
    required this.shippingFee,
    required this.selectedItems,
    required this.receiverName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.totalPrice,
    required this.loyaltyUsed,
    required this.voucherDiscount,
    required this.isVoucherApplied,
    required this.finalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng thành công'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Cảm ơn bạn đã đặt hàng!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    InfoRow(label: 'Mã đơn hàng:', value: orderId ?? '-'),
                    InfoRow(
                      label: 'Thời gian:',
                      value: DateFormat('HH:mm dd/MM/yyyy').format(timeCreate),
                    ),
                    InfoRow(label: 'Trạng thái:', value: 'pending'),
                    InfoRow(label: 'Tổng tiền hàng:', value: formatPrice(totalPrice)),
                    InfoRow(label: 'Điểm tích luỹ đã dùng:', value: formatPrice(loyaltyUsed.toDouble())),
                    InfoRow(label: 'Chiết khấu:', value: formatPrice(discount)),
                    InfoRow(label: 'Thuế:', value: formatPrice(tax)),
                    InfoRow(label: 'Phí vận chuyển:', value: formatPrice(shippingFee)),
                    InfoRow(label: 'Tổng thanh toán:', value: formatPrice(finalPrice)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chi tiết sản phẩm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...selectedItems.map((detail) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${detail.quantity}x'),
                ),
                title: Text('Sản phẩm: ${detail.variant.variantName}'),
                subtitle: Text(
                  'Đơn giá: ${formatPrice(detail.variant.sellingPrice)}\nThành tiền: ${formatPrice(detail.variant.sellingPrice*detail.quantity)}',
                ),
              ),
            )),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Quay về Trang chủ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}