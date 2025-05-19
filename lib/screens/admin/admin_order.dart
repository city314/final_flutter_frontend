import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/orderDetail.dart';
import '../../models/user.dart';
import '../../service/OrderService.dart';
import '../../service/ProductService.dart';
import '../../service/UserService.dart';
import 'component/SectionHeader.dart';
import '../../utils/format_utils.dart';

// Color palette
const Color kDark1    = Color.fromRGBO(11,  36,  51, 1);
const Color kDark2    = Color.fromRGBO(49,  68,  78, 1);
const Color kDark3    = Color.fromRGBO(73,  86,  98, 1);
const Color kLight1   = Color.fromRGBO(166, 188, 194,1);
const Color kLight2   = Color.fromRGBO(238, 249, 254,1);
const Color kAccent1  = Color.fromRGBO(76,  159, 195,1);
const Color kAccent2  = Color.fromRGBO(91,  241, 245,1);
enum DateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom,
}


// Extension to capitalize enum names
extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({Key? key}) : super(key: key);
  @override
  _AdminOrderScreenState createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  DateFilter _selectedFilter = DateFilter.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int _currentPage = 1;
  static const int _itemsPerPage = 20;
// Sample data; replace with real API fetch
  List<Order> _orders = [];
  List<OrderDetail> _orderDetails = [];
  List<User> _users = [];
  final Map<String, User> _usersByEmail = {};
  bool _isLoading = true;

  static const List<OrderStatus> _statuses = [
    OrderStatus.pending,
    OrderStatus.paid,
    OrderStatus.shipped,
    OrderStatus.complete,
    OrderStatus.canceled,
  ];

  bool _isInFilterRange(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case DateFilter.today:
        return time.isAfter(today);
      case DateFilter.yesterday:
        return time.isAfter(today.subtract(const Duration(days: 1))) && time.isBefore(today);
      case DateFilter.thisWeek:
        return time.isAfter(today.subtract(Duration(days: now.weekday - 1)));
      case DateFilter.thisMonth:
        return time.month == now.month && time.year == now.year;
      case DateFilter.custom:
        if (_customStartDate == null || _customEndDate == null) return true;
        return time.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
            time.isBefore(_customEndDate!.add(const Duration(days: 1)));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final orders = await OrderService.fetchOrders();
      orders.sort((a, b) => b.timeCreate.compareTo(a.timeCreate));
      final allDetails = <OrderDetail>[];
      final usersMap = <String, User>{};

      for (final o in orders) {
        final details = await OrderService.fetchOrderDetails(o.id ?? '');
        for (final d in details) {
          final variant = await ProductService.fetchVariantById(d.productId);
          d.variant = variant; // Giả sử OrderDetail có field `Variant? variant;`
        }
        allDetails.addAll(details);

        if (!usersMap.containsKey(o.userId)) {
          dynamic result = await UserService.fetchUserByEmail(o.userId ?? '');
          late Map<String, dynamic> userJson;

          // Nếu là list (tức trả về dạng [ {...} ])
          if (result is List && result.isNotEmpty && result.first is Map<String, dynamic>) {
            userJson = result.first as Map<String, dynamic>;
          } else if (result is Map<String, dynamic>) {
            userJson = result;
          } else {
            throw Exception('❌ Dữ liệu người dùng không hợp lệ: $result');
          }

          final user = User.fromJson(userJson);
          usersMap[o.userId ?? ''] = user;
        }
      }

      setState(() {
        _orders = orders;
        _orderDetails = allDetails;
        _usersByEmail.clear();
        _usersByEmail.addAll(usersMap);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi load đơn hàng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: _isLoading ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        )
        : Column(
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: const SectionHeader('Quản lý Đơn hàng'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<DateFilter>(
                  value: _selectedFilter,
                  items: DateFilter.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == DateFilter.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _customStartDate = picked.start;
                          _customEndDate = picked.end;
                          _selectedFilter = value!;
                          _currentPage = 1;
                        });
                      }
                    } else {
                      setState(() {
                        _selectedFilter = value!;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text('Trang $_currentPage'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => setState(() => _currentPage++),
                ),
              ],
            ),
            // TabBar
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                isScrollable: true,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.white,
                tabs: _statuses.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(s.name.capitalize()),
                )).toList(),
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: _statuses.map((status) {
                  final all = _orders
                      .where((o) => o.status == status && _isInFilterRange(o.timeCreate))
                      .toList();

                  final paged = all.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();
                  if (paged.isEmpty) {
                    return const Center(
                      child: Text('Không có đơn hàng', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paged.length,
                    itemBuilder: (context, i) {
                      final o = paged[i];
                      final user = _usersByEmail[o.userId] ??
                          User(
                            id: '', avatar: '', email: '', name: 'Unknown', gender: '', birthday: '',
                            phone: '', addresses: [], role: '', status: '', timeCreate: DateTime.now(),
                          );
                      // For pending orders, show action buttons
                      if (status == OrderStatus.pending) {
                        return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showDetail(o), // 👈 thêm dòng này
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey.shade300,
                                      child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(user.name),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        );
                      }
                      // Other statuses: default card
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDetail(o),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(user.name),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${o.timeCreate.toLocal()}'.split('.')[0],
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Order o) {
    OrderStatus selected = o.status;
    final user = _usersByEmail[o.userId] ??
        User(
          id: '', avatar: '', email: '', name: 'Unknown', gender: '', birthday: '',
          phone: '', addresses: [], role: '', status: '', timeCreate: DateTime.now(),
        );
    final details = _orderDetails.where((d) => d.orderId == o.id).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kDark3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Đơn hàng #${o.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Khách hàng: ${user.name}'),
              Text('Email: ${user.email}'),
              const Divider(),

              const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (user.addresses.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Người nhận: ${user.addresses.first.receiverName}'),
                    Text('SĐT: ${user.addresses.first.phone}'),
                    Text('Địa chỉ: ${user.addresses.first.address}'),
                  ],
                )
              else
                const Text('Không có địa chỉ'),

              const Divider(height: 24),
              const Text('Chi tiết sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d.variant?.variantName ?? d.productId),
                    Text('x${d.quantity}'),
                    Text(formatPrice((d.price * d.quantity).toDouble())),
                  ],
                ),
              )),
              const Divider(),

              _infoRow('Tổng tiền:', formatPrice(o.totalPrice)),
              _infoRow('Giảm giá từ sản phẩm:', formatPrice(o.discount)),
              _infoRow('Điểm đã dùng:', '${o.loyaltyPointUsed} điểm'),
              _infoRow('Giảm từ mã phiếu:', formatPrice(o.coupon)),
              _infoRow('Thuế:', formatPrice(o.tax)),
              _infoRow('Phí vận chuyển:', formatPrice(o.shippingFee)),
              const Divider(),
              _infoRow('Thành tiền:', formatPrice(o.finalPrice), bold: true),
              _infoRow('Ngày đặt hàng:', o.timeCreate.toLocal().toString().split('.')[0]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<OrderStatus>(
                      value: selected,
                      decoration: const InputDecoration(labelText: 'Trạng thái'),
                      items: _statuses.map((st) => DropdownMenuItem(
                        value: st,
                        child: Text(st.name.capitalize(), style: TextStyle(color: _statusColor(st))),
                      )).toList(),
                      onChanged: (v) => selected = v ?? selected,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await OrderService.updateOrderStatus(o.id ?? '', selected.name);
                        await OrderService.createOrderStatusHistory(o.id ?? '', selected.name);

                        setState(() {
                          final idx = _orders.indexWhere((o2) => o2.id == o.id);
                          _orders[idx] = o.copyWith(status: selected);
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${e.toString()}')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kAccent1),
                    child: const Text('Cập nhật'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.complete:
        return Colors.green;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }
}