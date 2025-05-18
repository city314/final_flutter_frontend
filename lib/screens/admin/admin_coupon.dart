import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/coupon.dart';
import '../../service/OrderService.dart';
import 'component/SectionHeader.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({Key? key}) : super(key: key);

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  List<Coupon> _coupons = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _maxUsesCtrl;

  int? _selectedDiscount;
  final List<int> _fixedDiscounts = [10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _discountCtrl = TextEditingController();
    _maxUsesCtrl = TextEditingController(text: '1');
    _loadCoupons();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    try {
      final data = await OrderService.fetchAllCoupons();
      setState(() {
        _coupons = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải coupon: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCouponDialog({Coupon? coupon}) {
    final isNew = coupon == null;
    if (!isNew) {
      _codeCtrl.text = coupon.code;
      _selectedDiscount = coupon.discountAmount as int?;
      _maxUsesCtrl.text = coupon.usageMax.toString();
    } else {
      _codeCtrl.clear();
      _selectedDiscount = null;
      _maxUsesCtrl.text = '1';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isNew ? 'Tạo Coupon mới' : 'Chỉnh sửa Coupon'),
        content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Mã (5 ký tự)'),
              maxLength: 5,
              validator: (v) {
                if (v == null || v.trim().length != 5) {
                  return 'Mã phải đúng 5 ký tự';
                }
                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v.trim())) {
                  return 'Chỉ được dùng A–Z và 0–9';
                }
                return null;
              },
            ),
            DropdownButtonFormField<int>(
              value: _selectedDiscount,
              decoration: const InputDecoration(labelText: 'Giá trị giảm'),
              items: _fixedDiscounts.map((d) => DropdownMenuItem(
                value: d,
                child: Text('₫$d'),
              )).toList(),
              validator: (v) => v == null ? 'Vui lòng chọn giá trị giảm' : null,
              onChanged: (v) => setState(() => _selectedDiscount = v),
            ),
            TextFormField(
              controller: _maxUsesCtrl,
              decoration: const InputDecoration(labelText: 'Giới hạn dùng tối đa'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 10) {
                  return 'Phải từ 1 đến 10';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final newCoupon = Coupon(
                id: isNew ? '' : coupon!.id,
                code: _codeCtrl.text.trim(),
                discountAmount: _selectedDiscount!,
                usageMax: int.parse(_maxUsesCtrl.text),
                usageTimes: isNew ? 0 : coupon!.usageTimes,
                timeCreate: isNew ? DateTime.now() : coupon!.timeCreate,
              );

              final success = isNew
                  ? await OrderService.createCoupon(newCoupon)
                  : await OrderService.updateCoupon(newCoupon);

              if (success) {
              context.pop();
                _loadCoupons();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isNew ? 'Đã tạo coupon' : 'Đã cập nhật coupon')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thao tác thất bại')),
                );
              }
            },
            child: Text(isNew ? 'Tạo' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteCoupon(Coupon c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá coupon "${c.code}" không?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              final success = await OrderService.deleteCoupon(c.id!);
              if (success) {
                context.pop();
                _loadCoupons();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xoá thất bại')));
              }
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCouponDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tạo Coupon',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Quản lý Coupon'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _coupons.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (_, i) {
                  final c = _coupons[i];
                  return ListTile(
                    title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Giảm ${c.discountAmount}đ • ${c.usageTimes}/${c.usageMax} lượt\n'
                          'Ngày tạo: ${c.timeCreate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(height: 1.4),
                    ),
                    isThreeLine: true,
                    onTap: () => _showCouponUsageDialog(c.code), // 👈 Thêm dòng này
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.usageTimes == 0)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCouponDialog(coupon: c),
                            tooltip: 'Chỉnh sửa',
                          )
                        else
                          const Icon(Icons.lock_outline, color: Colors.grey),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCoupon(c),
                          tooltip: 'Xoá',
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
    );
  }

  void _showCouponUsageDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đơn hàng đã dùng mã $code'),
        content: SizedBox(
          width: 400, // 👈 đảm bảo có chiều rộng cố định
          child: FutureBuilder<List<String>>(
            future: OrderService.fetchOrdersUsedCoupon(code),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Lỗi: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Chưa có đơn hàng nào sử dụng mã này.');
              }

              final orderIds = snapshot.data!;
              return SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: orderIds.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Đơn hàng #${orderIds[i]}'),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
