import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/productDiscount.dart';
import '../../service/ProductService.dart';
import 'component/SectionHeader.dart';
import '../../utils/format_utils.dart';

class AdminDiscountScreen extends StatefulWidget {
  const AdminDiscountScreen({Key? key}) : super(key: key);

  @override
  State<AdminDiscountScreen> createState() => _AdminDiscountScreenState();
}

class _AdminDiscountScreenState extends State<AdminDiscountScreen> {
  final _discountCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  // Searching
  String _searchQuery = '';
  // State cho filter
  String? _selectedCategory;
  String? _selectedBrand;
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  String _selectedDiscountStatus = 'Tất cả';
  final List<String> _discountStatuses = ['Tất cả', 'Đang khuyến mãi', 'Chưa khuyến mãi'];

  List<Product> _products = [];
  bool _isLoading = true;

  List<String> get _allCategories => ['Tất cả', ...{for (var p in _products) p.categoryName!}];
  List<String> get _allBrands => ['Tất cả', ...{for (var p in _products) p.brandName!}];

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Tất cả';
    _selectedBrand    = 'Tất cả';
    _loadProducts();
  }

  void _loadProducts() async {
    try {
      final fetched = await ProductService.fetchAllProducts();
      setState(() {
        _products = fetched;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi load sản phẩm: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final perc = int.tryParse(_discountCtrl.text.trim());
    if (perc == null || perc < 0 || perc > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập % giảm hợp lệ (0–50)')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')),
      );
      return;
    }

    // Tạo list ProductDiscount dựa trên model của bạn
    final discounts = _products
        .where((p) => _selectedIds.contains(p.id))
        .map((p) => ProductDiscount(
      productId:       p.id!,
      discountPercent: perc,
    ))
        .toList();

    final success = await ProductService.updateDiscounts(discounts);
    if (success) {
      setState(() {
        for (var p in _products) {
          if (_selectedIds.contains(p.id)) {
            p.discountPercent = perc; // Cập nhật trong UI luôn
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật giảm giá thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi cập nhật')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_isLoading) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    // Lọc theo tất cả điều kiện
    final filtered = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat    = _selectedCategory == 'Tất cả' || p.categoryName == _selectedCategory;
      final matchesBrand  = _selectedBrand    == 'Tất cả' || p.brandName    == _selectedBrand;
      final minPrice = double.tryParse(_minPriceCtrl.text) ?? 0;
      final maxPrice = double.tryParse(_maxPriceCtrl.text) ?? double.infinity;
      final matchesPrice = p.lowestPrice! >= minPrice && p.lowestPrice! <= maxPrice;

      final matchesDiscountStatus = _selectedDiscountStatus == 'Tất cả' ||
          (_selectedDiscountStatus == 'Đang khuyến mãi' && p.discountPercent != null && p.discountPercent! > 0) ||
          (_selectedDiscountStatus == 'Chưa khuyến mãi' && (p.discountPercent == null || p.discountPercent == 0));

      return matchesSearch && matchesCat && matchesBrand && matchesPrice && matchesDiscountStatus;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Quản lý Giảm giá sản phẩm'),
            const SizedBox(height: 16),

            // Nhập % giảm và chọn khoảng thời gian
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  decoration: const InputDecoration(
                    labelText: '% Giảm giá',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDiscountStatus,
              decoration: const InputDecoration(
                labelText: 'Trạng thái khuyến mãi',
                border: OutlineInputBorder(),
              ),
              items: _discountStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDiscountStatus = v!),
            ),
            const SizedBox(height: 24),
            // ————— Bộ lọc —————
            Row(
              children: [
                // Category
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items: _allCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 12),
                // Brand
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    decoration: const InputDecoration(
                      labelText: 'Thương hiệu',
                      border: OutlineInputBorder(),
                    ),
                    items: _allBrands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBrand = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Min Price
                Expanded(
                  child: TextField(
                    controller: _minPriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Giá từ (₫)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                // Max Price
                Expanded(
                  child: TextField(
                    controller: _maxPriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Đến (₫)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // —————————————— Thanh Search ——————————————
            TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm sản phẩm',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: 16),
            // Danh sách sản phẩm với Checkbox
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final checked = _selectedIds.contains(p.id);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) _selectedIds.add(p.id!);
                        else _selectedIds.remove(p.id!);
                      });
                    },
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Giá: ${formatPrice((p.lowestPrice ?? 0).toDouble())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Biến thể: ${p.variantCount}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if ((p.discountPercent ?? 0) > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Giảm ${p.discountPercent!.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Xác nhận áp dụng giảm giá'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
