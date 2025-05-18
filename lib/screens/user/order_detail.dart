import 'package:flutter/material.dart';
import 'CustomNavbar.dart';
import '../../utils/format_utils.dart';

class OrderDetail extends StatelessWidget {
  const OrderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu
    final String orderId = 'WN0302751962';
    final String orderTime = '02/04/2025 16:49';
    final String orderStatus = 'Đã giao hàng';
    final List<Map<String, dynamic>> products = [
      {
        'image': 'assets/images/product/laptop/acer/acer1.png',
        'name': 'Tai nghe chụp tai Dareu EH416-Đen',
        'quantity': 1,
        'price': 320000,
        'warranty': '1/4/2026',
      },
    ];
    final List<Map<String, String>> steps = [
      {'label': 'Đặt hàng', 'time': '16:49\n2/4/2025'},
      {'label': 'Xác nhận', 'time': '16:49\n2/4/2025'},
      {'label': 'Đang giao', 'time': '17:9\n2/4/2025'},
      {'label': 'Nhận hàng', 'time': '17:28\n2/4/2025'},
    ];
    final int currentStep = 3;
    final int total = 499000;
    final int discount = 179000;
    final int shipping = 0;
    final int pay = 320000;
    final String customerName = 'Mai Nguyen Phuong Trang';
    final String customerPhone = '0359514253';
    final String customerAddress = '915/92 Lê Văn Lương, Xã Phước Kiển, Huyện Nhà Bè, Hồ Chí Minh';
    final String shopPhone = '1800.2097';
    final String shopAddress = 'Tân Phong, Quận 7, TP HCM';
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;

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
      body: isAndroid
      ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                // Nút trở về + tiêu đề (với mobile sẽ có icon menu bên phải)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
                                    // Xử lý
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
                const SizedBox(height: 12),
                // Mã đơn, thời gian, trạng thái
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Mã đơn hàng: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      Text(orderTime, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: orderStatus == 'Đã giao hàng' ? Colors.green[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(orderStatus, style: TextStyle(color: orderStatus == 'Đã giao hàng' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Sản phẩm
                ...products.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            p['image'],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text('Số lượng: ${p['quantity']}', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Thời hạn bảo hành: ${p['warranty']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(p['price'].toDouble()),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )),
                // Tiến trình trạng thái đơn
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(steps.length, (i) => Column(
                      children: [
                        Icon(Icons.check_circle, color: i <= currentStep ? Colors.green : Colors.grey, size: 28),
                        const SizedBox(height: 4),
                        Text(steps[i]['label']!, style: TextStyle(fontWeight: FontWeight.bold, color: i <= currentStep ? Colors.green : Colors.grey)),
                        const SizedBox(height: 2),
                        Text(steps[i]['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    )),
                  ),
                ),
                // Thông tin thanh toán
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_balance_wallet, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPayRow('Tổng tiền sản phẩm:', total),
                      _buildPayRow('Giảm giá:', -discount),
                      _buildPayRow('Phí vận chuyển:', shipping == 0 ? 'Miễn phí' : shipping),
                      _buildPayRow('Phải thanh toán:', pay, bold: true),
                      _buildPayRow('Đã thanh toán:', pay, bold: true, green: true),
                    ],
                  ),
                ),
                // Thông tin khách hàng
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.account_circle, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(customerName),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(customerPhone),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customerAddress)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Thông tin hỗ trợ
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.support_agent, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Thông tin hỗ trợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(shopPhone),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(shopAddress)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút đánh giá sản phẩm
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showRatingDialog(context);
                    },
                    icon: Icon(Icons.star, color: Colors.yellow),
                    label: Text('Đánh giá sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAndroid && !isWindows)
            Container(
              width: 240,
              color: const Color(0xFFF7F7F7),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ListView(
                children: [
                  // Nút trở về + tiêu đề (với mobile sẽ có icon menu bên phải)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
                                      // Xử lý
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
                  const SizedBox(height: 12),
                  // Mã đơn, thời gian, trạng thái
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text('Mã đơn hàng: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Text(orderTime, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: orderStatus == 'Đã giao hàng' ? Colors.green[50] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(orderStatus, style: TextStyle(color: orderStatus == 'Đã giao hàng' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Sản phẩm
                  ...products.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              p['image'],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                                const SizedBox(height: 4),
                                Text('Số lượng: ${p['quantity']}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Thời hạn bảo hành: ${p['warranty']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatPrice(p['price'].toDouble()),
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )),
                  // Tiến trình trạng thái đơn
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        steps.length, (i) => Column(
                          children: [
                            Icon(Icons.check_circle, color: i <= currentStep ? Colors.green : Colors.grey, size: 28),
                            const SizedBox(height: 4),
                            Text(steps[i]['label']!, style: TextStyle(fontWeight: FontWeight.bold, color: i <= currentStep ? Colors.green : Colors.grey)),
                            const SizedBox(height: 2),
                            Text(steps[i]['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Thông tin thanh toán
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.account_balance_wallet, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPayRow('Tổng tiền sản phẩm:', total),
                        _buildPayRow('Giảm giá:', -discount),
                        _buildPayRow('Phí vận chuyển:', shipping == 0 ? 'Miễn phí' : shipping),
                        _buildPayRow('Phải thanh toán:', pay, bold: true),
                        _buildPayRow('Đã thanh toán:', pay, bold: true, green: true),
                      ],
                    ),
                  ),
                  // Thông tin khách hàng
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(customerName),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(customerPhone),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(customerAddress)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Thông tin hỗ trợ
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.support_agent, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Thông tin hỗ trợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(shopPhone),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(shopAddress)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Nút đánh giá sản phẩm
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showRatingDialog(context);
                      },
                      icon: Icon(Icons.star, color: Colors.yellow),
                      label: Text('Đánh giá sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),  
          ),
        ],
      ),
    );
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
          value is int
              ? Text(
                  '${value >= 0 ? '' : '-'}${formatPrice(value.abs().toDouble())}',
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: green
                        ? Colors.green
                        : (value < 0 ? Colors.red : Colors.black),
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

extension _OrderDetailRatingDialog on OrderDetail {
  void _showRatingDialog(BuildContext context) {
    int _rating = 5;
    TextEditingController _commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đánh giá sản phẩm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Bình luận của bạn',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Xử lý lưu đánh giá (_rating, _commentController.text)
                    Navigator.pop(context);
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 