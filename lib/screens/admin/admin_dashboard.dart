import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'component/SectionHeader.dart';
import '../../service/ProductService.dart';
import '../../service/UserService.dart';
import '../../service/OrderService.dart';
import '../../service/CartService.dart';
import '../../service/WebSocketService.dart';
import 'package:cpmad_final/models/order.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalUsers = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  double totalRevenue = 0.0;
  // Danh sách đơn hàng
  List<Order> _ordersList = [];

  // Dữ liệu cho LineChart
  List<FlSpot> _spots = [];
  // Dữ liệu cho Pie Chart
  List<PieChartSectionData> pieSections = [];

  // Bộ màu cho từng phần
  final List<Color> _pieColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.deepPurpleAccent,
    Colors.teal,
    Colors.pink,
  ];

  // Khởi tạo các service instance
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final WebSocketService _webSocketService = WebSocketService();

  final List<String> ranges = [
    'Hôm nay',
    'Tuần này',
    'Tháng này',
    'Quý này',
    'Năm nay',
    'Tùy chỉnh',
  ];
  String selectedRange = 'Tháng này';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _webSocketService.connect((review) {
      // TODO: Handle new review events if needed
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      // Tải người dùng và sản phẩm chung
      final users = await UserService.fetchUsers();
      final products = await ProductService.fetchAllProducts();
      final orders = await OrderService.fetchAllOrders();

      // Tải danh mục và tính số sản phẩm mỗi loại
      final categories = await ProductService.fetchAllCategory();
      final List<PieChartSectionData> sections = [];
      for (var i = 0; i < categories.length; i++) {
        final cat = categories[i];
        final prods = await _productService.fetchProductsByCategory(cat.id!);
        final color = _pieColors[i % _pieColors.length];
        sections.add(
          PieChartSectionData(
            value: prods.length.toDouble(),
            title: cat.name,
            radius: 60,
            color: color,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }

      final now = DateTime.now();
      DateTime start;
      // Xác định start dựa vào selectedRange
      switch (selectedRange) {
        case 'Hôm nay':
          start = DateTime(now.year, now.month, now.day);
          break;
        case 'Tuần này':
          start = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          break;
        case 'Tháng này':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'Quý này':
          final quarter    = ((now.month - 1) ~/ 3) + 1;
          final startMonth = (quarter - 1) * 3 + 1;
          start = DateTime(now.year, startMonth, 1);
          break;
        case 'Năm nay':
          start = DateTime(now.year, 1, 1);
          break;
        default: // 'Tùy chỉnh'
        // TODO: show DatePicker để người dùng tự chọn
          start = DateTime(now.year, now.month, now.day);
      }

      // Lọc orders trong khoảng [start, now]
      final filteredOrders = orders.where((o) {
        return o.timeCreate.isAfter(start.subtract(const Duration(seconds: 1)))
            && o.timeCreate.isBefore(now.add(const Duration(seconds: 1)));
      }).toList();

      // Tính tổng doanh thu, số đơn
      final revenue = filteredOrders.fold<double>(
          0.0, (sum, o) => sum + o.totalPrice);

      // Tính data cho LineChart (theo ngày trong khoảng)
      final days = now.difference(start).inDays + 1;
      final dailyRevenue = List<double>.filled(days, 0.0);
      for (var o in filteredOrders) {
        final idx = now.difference(o.timeCreate).inDays;
        if (idx >= 0 && idx < days) {
          dailyRevenue[days - 1 - idx] += o.totalPrice;
        }
      }
      final spots = List<FlSpot>.generate(
          days, (i) => FlSpot(i.toDouble(), dailyRevenue[i]));

      setState(() {
        totalUsers = users.length;
        totalProducts = products.length;
        pieSections = sections;
        totalOrders   = filteredOrders.length;
        totalRevenue  = revenue;
        _ordersList  = filteredOrders;
        _spots      = spots;
      });
    } catch (e, stackTrace) {
      // Đây phải là string interpolation, không phải raw string
      debugPrint('Error loading dashboard data: $e\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1200;

        Widget content = Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOverviewGrid(crossAxisCount: isMobile ? 1 : isTablet ? 2 : 4),
            const SizedBox(height: 32),
            _buildChartCard('📈 Doanh thu theo thời gian', _buildLineChart()),
            const SizedBox(height: 32),
            _buildChartCard('📊 Tỷ lệ loại sản phẩm bán chạy', _buildPieChart()),
          ],
        );

        if (isMobile || isTablet) {
          return Container(
            color: const Color(0xFFF5F6FA),
            child: ListView(padding: const EdgeInsets.all(16), children: [content]),
          );
        } else {
          return Container(
            color: const Color(0xFFF5F6FA),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const SectionHeader('Tổng quan'),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: selectedRange,     // ← dùng biến state ở đây
                underline: const SizedBox(),
                items: ranges
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedRange = value);
                  _loadDashboardData();      // load lại dữ liệu theo range mới
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid({required int crossAxisCount}) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _DashboardCard(title: 'Tổng người dùng', value: '$totalUsers', icon: Icons.people),
        _DashboardCard(title: 'Tổng sản phẩm', value: '$totalProducts', icon: Icons.shopping_bag),
        _DashboardCard(title: 'Đơn hàng', value: totalOrders.toString(), icon: Icons.shopping_cart),
        _DashboardCard(title: 'Doanh thu', value: '₫${totalRevenue.toStringAsFixed(0)}', icon: Icons.bar_chart),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Tính maxY tự động (lấy giá trị lớn nhất trong _spots)
    final maxY = _spots.isNotEmpty
        ? _spots.map((e) => e.y).reduce(max) * 1.2
        : 5.0;

    // 2. Đảm bảo gridInterval là double
    final double gridInterval = maxY > 0.0 ? maxY / 4.0 : 1.0;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxY > 0 ? maxY : 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gridInterval, // chia 4 khoảng ngang
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const labels = ['-6', '-5', '-4', '-3', '-2', '-1', 'Hôm nay'];
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Text(labels[idx], style: const TextStyle(fontSize: 12));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(right: 4),
                child:
                Text('Doanh thu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5000000, // mỗi 5 triệu
                getTitlesWidget: (value, meta) {
                  // chỉ show khi đúng bội số 5tr
                  if (value % 5000000 == 0) {
                    final m = (value / 1000000).toStringAsFixed(0);
                    return Text('${m}M', style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (pieSections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return PieChart(PieChartData(
      sectionsSpace: 4,
      centerSpaceRadius: 30,
      sections: pieSections,
    ));
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({Key? key, required this.title, required this.value, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}