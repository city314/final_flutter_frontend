import 'dart:convert';

import 'package:cpmad_final/pattern/current_user.dart';
import 'package:cpmad_final/service/OrderService.dart';
import 'package:cpmad_final/service/ProductService.dart';
import 'package:cpmad_final/service/UserService.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/CartService.dart';
import '../../utils/format_utils.dart';

import '../../models/selectedproduct.dart';
import 'CustomNavbar.dart';

class CartSummary extends StatefulWidget {
  final List<SelectedProduct> selectedItems;

  const CartSummary({
    Key? key,
    required this.selectedItems,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CartSummary> {
  bool _useCoins = false;
  final TextEditingController _voucherController = TextEditingController();
  double _voucherDiscount = 0;
  String? _voucherMessage;
  bool _isVoucherApplied = false;
  final TextEditingController _coinController = TextEditingController();
  int loyalty = 0;
  int lyt = 0;
  List<Map<String, dynamic>> _addressList = [];
  Map<String, dynamic>? _selectedAddress;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Khai báo form key để validate
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (CurrentUser().isLogin) {
      _loadUserInfo();
    }
  }

  String getDefaultFullAddress(Map<String, dynamic> user) {
    final addresses = user['address'] as List<dynamic>? ?? [];
    final defaultAddr = addresses.firstWhere(
          (addr) => addr['default'] == true,
      orElse: () => null,
    );

    if (defaultAddr == null) return 'Không có địa chỉ mặc định';

    return '${defaultAddr['address']}';
  }

  void _loadUserInfo() async {
    if (!CurrentUser().isLogin) return;

    try {
      final productIds = widget.selectedItems
          .map((e) => e.variant.productId)
          .toList();
      final user = await UserService.fetchUserByEmail(CurrentUser().email ?? '');
      loyalty = user['loyalty_point'];
      lyt = loyalty;
      if (user != null) {
        setState(() {
          final addresses = user['address'] as List<dynamic>? ?? [];
          _addressList = List<Map<String, dynamic>>.from(addresses);
          _selectedAddress = addresses.firstWhere((addr) => addr['default'] == true, orElse: () => addresses.isNotEmpty ? addresses[0] : null);

          final defaultAddr = addresses.firstWhere(
                (addr) => addr['default'] == true,
            orElse: () => null,
          );
          _nameCtrl.text = defaultAddr != null ? defaultAddr['receiver_name'] ?? '' : '';
          _phoneCtrl.text = user['phone'] ?? '';
          _emailCtrl.text = user['email'] ?? '';
          _addressCtrl.text = getDefaultFullAddress(user);
        });
      }
    } catch (e) {
      print('❌ Lỗi khi load thông tin người dùng: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Theme
            .of(context)
            .primaryColor),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Tính toán trước totalPrice, totalDiscount, finalAmount
    double totalPrice = 0;
    double totalDiscount = 0;

    for (var item in widget.selectedItems) {
      final price = item.variant.sellingPrice;
      final discount = item.discount;
      totalPrice += price * item.quantity;
      totalDiscount += price * item.quantity * (discount / 100);
    }

    final shippingFee = 20000.0;
    final tax = totalPrice * 0.03;
    double finalAmount = totalPrice - totalDiscount - loyalty * 1000 - _voucherDiscount + tax + shippingFee;

    // Xác định layout rộng hay hẹp
    final isWide = MediaQuery.of(context).size.width >= 800;

    // Chiều cao dành cho list trên mobile (40% màn hình)
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = screenHeight * 0.4;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
        // ---- Web/Desktop: 2 cột ----
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildProductList(),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummary(totalPrice, totalDiscount, finalAmount, shippingFee, tax),
                    const SizedBox(height: 24),
                    Text(
                      'Thông tin giao hàng',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buildShippingForm(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _onConfirmPressed,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Xác nhận thanh toán'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
        // ---- Mobile: xếp dọc, cuộn được ----
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: listHeight,
                child: _buildProductList(),
              ),
              const SizedBox(height: 24),
              _buildSummary(totalPrice, totalDiscount, finalAmount, shippingFee, tax),
              const SizedBox(height: 24),
              Text(
                'Thông tin giao hàng',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildShippingForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProductList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.selectedItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = widget.selectedItems[index];
        final variant = item.variant;
        final imageUrl = variant.images.isNotEmpty ? variant
            .images[0]['base64'] ?? '' : '';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.memory(base64Decode(imageUrl), width: 50,
                  height: 50,
                  fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40),
            ),
            title: Text(variant.variantName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Số lượng: ${item.quantity}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatPrice(variant.sellingPrice),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(double total, double discount, double finalAmount, double shippingFee, double tax) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _coinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sử dụng Điểm KHTT (tối đa: ${lyt.toStringAsFixed(0)})',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final input = int.tryParse(value);
                    if (input == null || input < 0) return 'Điểm không hợp lệ';
                    if (input > lyt) return 'Bạn chỉ có tối đa $lyt điểm';
                    return null;
                  },
                  onChanged: (value) {
                    final input = int.tryParse(value) ?? 0;
                    setState(() {
                      loyalty = input.clamp(0, lyt);
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.discount, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    labelText: 'Mã phiếu giảm giá',
                    suffixIcon: TextButton(
                        child: const Text('Áp dụng'),
                        onPressed: () async {
                          final code = _voucherController.text.trim();
                          final info = await OrderService.checkCoupon(code);
                          if (info != null) {
                            final remaining = info.usageMax - info.usageTimes;

                            // Tính lại total price và total discount hiện tại
                            double totalPrice = 0;
                            double totalDiscount = 0;
                            for (var item in widget.selectedItems) {
                              final price = item.variant.sellingPrice;
                              final discount = item.discount;
                              totalPrice += price * item.quantity;
                              totalDiscount +=
                                  price * item.quantity * (discount / 100);
                            }

                            double subtotalAfterDiscounts = totalPrice -
                                totalDiscount - loyalty * 1000;

                            // Kiểm tra hiệu lực mã
                            if (info.discountAmount <= subtotalAfterDiscounts) {
                              setState(() {
                                _voucherDiscount =
                                    info.discountAmount.toDouble();
                                _isVoucherApplied = true;
                                _voucherMessage =
                                'Mã ${info.code} áp dụng thành công (-${info
                                    .discountAmount.toStringAsFixed(0)} đ)\n'
                                    'Số lượt còn lại: $remaining / ${info
                                    .usageMax}';
                              });
                            } else {
                              setState(() {
                                _voucherDiscount = 0;
                                _voucherMessage =
                                'Mã không hợp lệ: Giá trị đơn hàng phải >= ${info
                                    .discountAmount} để áp dụng mã này.';
                                _isVoucherApplied = false;
                              });
                            }
                          } else {
                            setState(() {
                              _voucherDiscount = 0;
                              _voucherMessage =
                              'Mã không hợp lệ hoặc đã hết lượt dùng';
                              _isVoucherApplied = false;
                            });
                          }
                        }
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_voucherMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _voucherMessage!,
                style: TextStyle(
                  color: _isVoucherApplied ? Colors.green : Colors.red,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _priceRow('Tạm tính', total),
          _priceRow('Giảm giá ($discount%)', discount),
          _priceRow('Giảm từ điểm KHTT', loyalty * 1000 as double),
          _priceRow('Giảm từ mã phiếu', _voucherDiscount),
          _priceRow('Thuế (3%)', tax),
          _priceRow('Phí vận chuyển', shippingFee),
          const Divider(),
          _priceRow('Thành tiền', finalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatPrice(value),
            style: bold
                ? const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (CurrentUser().isLogin && _addressList.length > 1)
          ...[
            const Text('Chọn địa chỉ giao hàng:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedAddress,
              items: _addressList.map((addr) {
                final label = '${addr['receiver_name']} - ${addr['address']}';
                return DropdownMenuItem(
                  value: addr,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAddress = value;
                  _nameCtrl.text = value?['receiver_name'] ?? '';
                  _phoneCtrl.text = value?['phone'] ?? '';
                  _addressCtrl.text = value?['address'] ?? '';
                });
              },
              decoration: _inputDecoration('Địa chỉ giao hàng', Icons.location_on),
            ),
            const SizedBox(height: 16),
          ],
        TextFormField(
          controller: _nameCtrl,
          decoration: _inputDecoration('Họ và tên', Icons.person),
          validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('Số điện thoại', Icons.phone),
          validator: (v) => v!.length < 9 ? 'Số điện thoại không hợp lệ' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Email', Icons.email),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }

              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Email không hợp lệ';
              }

              return null;
            }
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressCtrl,
          decoration: _inputDecoration('Địa chỉ', Icons.location_on),
          maxLines: 2,
          validator: (v) => v!.isEmpty ? 'Nhập địa chỉ' : null,
        ),
      ],
    );
  }

  void _onConfirmPressed() async {
    double totalPrice = 0;
    double totalDiscount = 0;

    for (var item in widget.selectedItems) {
      final price = item.variant.sellingPrice;
      final discount = item.discount;
      totalPrice += price * item.quantity;
      totalDiscount += price * item.quantity * (discount / 100);
    }

    final shippingFee = 20000.0;
    final tax = totalPrice * 0.03;
    double finalAmount = totalPrice - totalDiscount - loyalty * 1000 - _voucherDiscount + tax + shippingFee;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (!CurrentUser().isLogin) {
      final existing = await UserService.checkIfEmailExists(email);
      if (existing) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Email đã được đăng ký. Vui lòng đăng nhập để tiếp tục.'),
          backgroundColor: Colors.red,
        ));
        return;
      } else {
        final password = 'user123';
        print(name);
        print(email);
        print(address);
        final success = await UserService.registerGuest(
          email,
          name,
          password,
          address,
        );
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tạo tài khoản thất bại.'),
            backgroundColor: Colors.red,
          ));
          return;
        } else {
          final oldUserId = await SharedPreferences.getInstance().then((prefs) => prefs.getString('guestId') ?? '');
          final newUserId = email; // hoặc userId thực tế nếu bạn dùng _id
          if (oldUserId.isNotEmpty && newUserId.isNotEmpty) {
            await CartService.updateCartUserId(oldUserId, newUserId);
            // Cập nhật lại user_id trong SharedPreferences để các thao tác sau dùng user mới
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('guestId', newUserId);
          }
        }
      }
    }
    if (_coinController.text.trim().isEmpty) {
      loyalty = 0;
    }
    // TODO: Gửi orderPayload đến OrderService
    final orderPayload = {
      "user_id": CurrentUser().isLogin ? CurrentUser().email : email, // hoặc lấy từ SharedPreferences
      "total_price": totalPrice,
      "loyalty_point_used": loyalty,
      "discount": totalDiscount,
      "coupon": _voucherDiscount,
      "tax": tax,
      "shipping_fee": shippingFee,
      "final_price": finalAmount,
      "status": "pending",
    };

    final orderId = await OrderService.createOrder(orderPayload);

    if (orderId != null) {
      final orderDetails = widget.selectedItems.map((item) => {
        "order_id": orderId,
        "variant_id": item.variant.id,
        "quantity": item.quantity,
        "price": item.variant.sellingPrice,
      }).toList();

      await OrderService.saveOrderStatus(
        orderId: orderId,
        status: "pending", // hoặc "created"
      );

      final success = await OrderService.createOrderDetails(orderDetails);
      if (success) {
        //Trừ số lần sử dụng coupon
        if (_isVoucherApplied) {
          await OrderService.useCoupon(_voucherController.text.trim());
          await OrderService.saveCouponUsage(
            orderId: orderId,
            couponCode: _voucherController.text.trim(),
          );
        }

        // Cập nhật loyalty
        final earnedPoints = (finalAmount / 10000).floor();
        final loyaltyChange = (loyalty * -1) + earnedPoints;
        await UserService.updateLoyalty(email, loyaltyChange);

        // Cập nhật stock và soldCount
        for (var item in widget.selectedItems) {
          await ProductService.updateVariantStock(item.variant.id ?? '', -item.quantity);
          await ProductService.updateProductSold(item.variant.productId, item.quantity);
        }

        // Xoá khỏi giỏ hàng
        await CartService.removeItemsFromCart(widget.selectedItems.map((e) => e.variant.id ?? '').toList(), email);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đặt hàng thành công!'),
          backgroundColor: Colors.green,
        ));

        await OrderService.sendConfirmationEmail(
          email: email,
          name: name,
          orderId: orderId,
          finalAmount: finalAmount,
          items: widget.selectedItems.map((item) => {
            'variantName': item.variant.variantName,
            'quantity': item.quantity,
            'price': item.variant.sellingPrice,
          }).toList(),
        );
        context.pushNamed(
          'orderDone',
          extra: {
            'orderId': orderId,
            'timeCreate': DateTime.now(),
            'tax': tax,
            'discount': totalDiscount,
            'shippingFee': shippingFee,
            'selectedItems': widget.selectedItems,
            'receiverName': _nameCtrl.text,
            'phoneNumber': _phoneCtrl.text,
            'email': _emailCtrl.text,
            'address': _addressCtrl.text,
            'totalPrice': totalPrice,
            'finalPrice': finalAmount,
            'loyaltyUsed': int.tryParse(_coinController.text) ?? 0,
            'voucherDiscount': _voucherDiscount,
            'isVoucherApplied': _isVoucherApplied,
          },
        );
        // Navigate hoặc reset state
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi khi lưu chi tiết đơn hàng'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi tạo đơn hàng'),
        backgroundColor: Colors.red,
      ));
    }
  }
}