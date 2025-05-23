// Enhanced AdminDashboardScreen with profit, quantity, and comparison chart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
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
  double totalProfit = 0.0;
  int totalQuantitySold = 0;
  List<Order> _ordersList = [];
  List<FlSpot> _spots = [];
  int totalStock = 0;
  int totalSold = 0;

  List<PieChartSectionData> pieSections = [];
  Map<String, int> _categorySales = {};
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
  final ProductService _productService = ProductService();
  final WebSocketService _webSocketService = WebSocketService();

  final List<String> ranges = [
    'Hôm nay', 'Tuần này', 'Tháng này', 'Quý này', 'Năm nay', 'Tùy chỉnh'
  ];
  String selectedRange = 'Tháng này';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _webSocketService.connect((review) {});
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final users = await UserService.fetchUsers();
      final products = await ProductService.fetchAllProducts();
      final orders = await OrderService.fetchAllOrders();
      final categories = await ProductService.fetchAllCategory();

      totalStock = 0;
      totalSold = 0;
      for (var p in products) {
        final variants = await ProductService.fetchVariantsByProduct(p.id ?? '');
        for (var v in variants) {
          totalStock += v.stock ?? 0;
        }
        totalSold += p.soldCount ?? 0;
      }

      final now = DateTime.now();
      _endDate = now;
      DateTime start;
      switch (selectedRange) {
        case 'Hôm nay': start = DateTime(now.year, now.month, now.day); break;
        case 'Tuần này': start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)); break;
        case 'Tháng này': start = DateTime(now.year, now.month, 1); break;
        case 'Quý này':
          final quarter = ((now.month - 1) ~/ 3) + 1;
          final startMonth = (quarter - 1) * 3 + 1;
          start = DateTime(now.year, startMonth, 1); break;
        case 'Năm nay': start = DateTime(now.year, 1, 1); break;
        default: start = DateTime(now.year, now.month, now.day);
      }
      _startDate = start;
      final filteredOrders = orders.where((o) {
        return o.timeCreate.isAfter(start) && o.timeCreate.isBefore(now);
      }).toList();

      double revenue = 0.0;
      double profit = 0.0;
      int quantity = 0;

      for (var o in filteredOrders) {
        revenue += o.finalPrice;
        profit += o.profit!;
        for (var item in o.items ?? []) {
          quantity += item.quantity as int;
        }
      }

      final List<PieChartSectionData> sections = [];
      for (var i = 0; i < categories.length; i++) {
        final cat = categories[i];
        final prods = await _productService.fetchProductsByCategory(cat.id!);
        sections.add(
          PieChartSectionData(
            value: prods.length.toDouble(),
            title: cat.name,
            radius: 60,
            color: _pieColors[i % _pieColors.length],
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }

      final days = now.difference(start).inDays + 1;
      final dailyRevenue = List<double>.filled(days, 0.0);
      for (var o in filteredOrders) {
        final idx = now.difference(o.timeCreate).inDays;
        if (idx >= 0 && idx < days) {
          dailyRevenue[days - 1 - idx] += o.totalPrice;
        }
      }
      final spots = List<FlSpot>.generate(days, (i) => FlSpot(i.toDouble(), dailyRevenue[i]));
      print(totalSold);
      print(totalStock);
      if (!_isDisposed) setState(() {
        totalUsers = users.length;
        totalProducts = products.length;
        pieSections = sections;
        totalOrders = filteredOrders.length;
        totalRevenue = revenue;
        totalProfit = profit;
        totalQuantitySold = quantity;
        _ordersList = filteredOrders;
        _spots = spots;
      });
    } catch (e, stack) {
      debugPrint('Error loading dashboard data: $e\n$stack');
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
            if (_startDate != null && _endDate != null)
              Text(
                'Từ ${DateFormat('dd/MM/yyyy').format(_startDate!)} đến ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
            _buildOverviewGrid(crossAxisCount: isMobile ? 1 : isTablet ? 2 : 4),
            const SizedBox(height: 32),
            _buildChartCard('📈 Doanh thu theo thời gian', _buildLineChart()),
            const SizedBox(height: 32),
            _buildChartCard('📊 Tỷ lệ loại sản phẩm bán chạy', _buildPieChart()),
            const SizedBox(height: 32),
            _buildChartCard('📋 So sánh: Doanh thu - Lợi nhuận', _buildComparisonChart()),
            const SizedBox(height: 32),
            _buildChartCard('🗓 Doanh thu & Lợi nhuận theo tháng', _buildRevenueProfitBarChart('month')),
            const SizedBox(height: 32),
            _buildChartCard('📦 So sánh tồn kho & sản phẩm đã bán', _buildProductStockSoldChart()),


          ],
        );

        return Container(
          color: const Color(0xFFF5F6FA),
          child: isMobile || isTablet
              ? ListView(padding: const EdgeInsets.all(16), children: [content])
              : SingleChildScrollView(padding: const EdgeInsets.all(16), child: content),
        );
      },
    );
  }

  Widget _buildComparisonChart() {
    if (totalRevenue.isNaN || totalProfit.isNaN || totalQuantitySold.isNaN) {
      return const Text('Dữ liệu không hợp lệ');
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalRevenue, color: Colors.blue)], showingTooltipIndicators: [0]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalProfit, color: Colors.green)], showingTooltipIndicators: [0]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0: return const Text('Doanh thu');
                  case 1: return const Text('Lợi nhuận');
                  default: return const SizedBox();
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
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
        _DashboardCard(title: 'Số người dùng mới', value: '$totalUsers', icon: Icons.people),
        _DashboardCard(title: 'Tổng sản phẩm', value: '$totalProducts', icon: Icons.shopping_bag),
        _DashboardCard(title: 'Đơn hàng', value: totalOrders.toString(), icon: Icons.shopping_cart),
        _DashboardCard(title: 'Doanh thu', value: '₫${totalRevenue.toStringAsFixed(0)}', icon: Icons.bar_chart),
        _DashboardCard(title: 'Lợi nhuận', value: '₫${totalProfit.toStringAsFixed(0)}', icon: Icons.stacked_line_chart),
      ],
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
                value: selectedRange,
                underline: const SizedBox(),
                items: ranges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedRange = value);
                  _loadDashboardData();
                },
              ),
            ),
          ),
        ],
      ),
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
    if (_spots.isEmpty || _spots.any((e) => e.y.isNaN)) {
      return const Center(child: Text('Không có dữ liệu hiển thị'));
    }

    final maxY = _spots.isNotEmpty ? _spots.map((e) => e.y).reduce(max) * 1.2 : 5.0;
    final double gridInterval = maxY > 0.0 ? maxY / 4.0 : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY : 5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: gridInterval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
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
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5000000,
              getTitlesWidget: (value, meta) {
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
    );
  }

  Widget _buildProductStockSoldChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: totalStock.toDouble(), color: Colors.blue, width: 10)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: totalSold.toDouble(), color: Colors.green, width: 10)
          ]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0: return const Text("Tồn kho");
                  case 1: return const Text("Đã bán");
                  default: return const SizedBox();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        borderData: FlBorderData(show: false),
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

  Map<String, double> _aggregateByInterval(List<Order> orders, String type, {bool onlyRevenue = false}) {
    final now = DateTime.now();
    final out = <String, double>{};

    for (var o in orders) {
      DateTime dt = o.timeCreate;
      String key;

      switch (type) {
        case 'year':
          key = '${dt.year}';
          break;
        case 'quarter':
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q';
          break;
        case 'month':
          key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          break;
        case 'week':
          final w = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$w';
          break;
        default:
          key = '${dt.year}-${dt.month}-${dt.day}';
      }

      final value = onlyRevenue ? o.totalPrice : o.profit ?? 0;
      out[key] = (out[key] ?? 0) + value;
    }

    return out;
  }

  Widget _buildRevenueProfitBarChart(String intervalType) {
    final map = _aggregateByInterval(_ordersList, intervalType, onlyRevenue: true);
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (x, _) {
                final key = map.keys.elementAt(x.toInt().clamp(0, map.length - 1));
                return Text(key, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: List.generate(map.length, (i) {
          return BarChartGroupData(x: i, barsSpace: 4, barRods: [
            BarChartRodData(toY: totalRevenue, color: Colors.blue, width: 8),
            BarChartRodData(toY: totalProfit, color: Colors.green, width: 8),
          ]);
        }),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({Key? key, required this.title, required this.value, required this.icon}) : super(key: key);

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
