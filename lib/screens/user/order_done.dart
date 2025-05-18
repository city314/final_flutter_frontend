// Màn hình hiển thị đặt hàng thành công và chi tiết đơn hàng
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/orderDetail.dart';
class OrderSuccessPage extends StatelessWidget {
  // final Order order;
  // final List<OrderDetail> orderDetails;
  final order = Order(
    id: 'ORD123456',
    userId: 'USER987',
    totalPrice: 100000,
    loyaltyPointUsed: 500,
    discount: 5000,
    tax: 2000,
    shippingFee: 10000,
    finalPrice: 106500,
    status: OrderStatus.complete,
    timeCreate: DateTime.now(), coupon: 0,
  );
  final orderDetails = [
    OrderDetail(
      id: 'OD1',
      orderId: 'ORD123456',
      productId: 'PRD001',
      quantity: 2,
      price: 30000,
    ),
    OrderDetail(
      id: 'OD2',
      orderId: 'ORD123456',
      productId: 'PRD002',
      quantity: 1,
      price: 40000,
    ),
  ];
  // const OrderSuccessPage({
  //   Key? key,
  //   required this.order,
  //   required this.orderDetails,
  // }) : super(key: key);

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
                    InfoRow(label: 'Mã đơn hàng:', value: order.id ?? '-'),
                    InfoRow(
                      label: 'Thời gian:',
                      value: DateFormat('HH:mm dd/MM/yyyy').format(order.timeCreate),
                    ),
                    InfoRow(label: 'Trạng thái:', value: order.status.toString().split('.').last),
                    InfoRow(label: 'Tổng tiền hàng:', value: '${order.totalPrice}'),
                    InfoRow(label: 'Điểm tích luỹ đã dùng:', value: '${order.loyaltyPointUsed}'),
                    InfoRow(label: 'Chiết khấu:', value: '${order.discount}'),
                    InfoRow(label: 'Thuế:', value: '${order.tax}'),
                    InfoRow(label: 'Phí vận chuyển:', value: '${order.shippingFee}'),
                    InfoRow(label: 'Tổng thanh toán:', value: '${order.finalPrice}'),
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
            ...orderDetails.map((detail) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${detail.quantity}x'),
                ),
                title: Text('Sản phẩm: ${detail.productId}'),
                subtitle: Text(
                  'Đơn giá: ${detail.price}\nThành tiền: ${detail.price*detail.quantity}',
                ),
              ),
            )),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
