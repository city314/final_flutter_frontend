import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../service/ProductService.dart';
import 'package:cpmad_final/models/product.dart';
import 'package:cpmad_final/models/category.dart';
import 'package:cpmad_final/models/brand.dart';
import 'component/SectionHeader.dart';
import '../../utils/format_utils.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  Brand? _selectedBrand;
  Category? _selectedCategory;
  //Scroll
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_allProducts);
    _loadProducts();
    _searchCtrl.addListener(_onSearch);
    _minPriceCtrl.addListener(_applyFilters);
    _maxPriceCtrl.addListener(_applyFilters);
    _verticalController   = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.fetchAllProducts();
      final brands     = await ProductService.fetchAllBrand();
      final categories = await ProductService.fetchAllCategory();

      setState(() {
        _allProducts.clear();
        _allProducts.addAll(products);
        _filteredProducts = List.from(products);
        _brands           = [Brand(id: '', name: 'Tất cả'), ...brands];
        _categories       = [Category(id: '', name: 'Tất cả'), ...categories];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải sản phẩm: $e')));
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
    });
  }

  void _applyFilters() {
    final q      = _searchCtrl.text.toLowerCase();
    final minP   = double.tryParse(_minPriceCtrl.text) ?? 0;
    final maxP   = double.tryParse(_maxPriceCtrl.text) ?? double.infinity;

    // Lấy id của brand/category, nếu null thì thành chuỗi rỗng
    final selectedBrandId    = _selectedBrand?.id ?? '';
    final selectedCategoryId = _selectedCategory?.id ?? '';

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final nameMatch     = p.name.toLowerCase().contains(q);

        // Nếu chưa chọn (id == '') thì luôn match, ngược lại so với p.brandId
        final brandMatch    = selectedBrandId.isEmpty || p.brandId == selectedBrandId;
        final categoryMatch = selectedCategoryId.isEmpty || p.categoryId == selectedCategoryId;

        final price         = p.lowestPrice ?? 0;
        final priceMatch    = price >= minP && price <= maxP;
        return nameMatch && brandMatch && categoryMatch && priceMatch;
      }).toList();
    });
  }

  void _openDetail({Product? product}) async {
    final isNew = product == null;
    final p = product ?? Product(
      id: null,
      name: '',
      categoryId: '',
      categoryName: '',
      brandId: '',
      brandName: '',
      description: '',
      stock: 0,
      lowestPrice: 0,
      discountPercent: 0,
      images: [],
      timeAdd: DateTime.now(),
      variants: [],
    );

    final result = await context.push<Product>(
      '/admin/product-detail',
      extra: {
        'product': p,
        'isNew': isNew,
      },
    );

    if (result != null) {
      setState(() {
        if (isNew) {
          _allProducts.add(result);
        } else {
          final idx = _allProducts.indexWhere((e) => e.id == result.id);
          if (idx != -1) {
            _allProducts[idx] = result;
            _allProducts[idx].variantCount = result.variants.length; // Cập nhật lại count thủ công
          }
        }
        _onSearch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Quản lý sản phẩm'), // thêm SectionHeader
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            // --- FILTERS ---
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Brand>(
                    value: _selectedBrand,
                    items: _brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Nhãn hiệu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (b) {
                      _selectedBrand = b;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (c) {
                      _selectedCategory = c;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Giá từ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Giá đến',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: screenWidth < 1000
                  ? _buildProductListMobile()
                  : _buildProductTableDesktop(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDetail(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Trong class _AdminProductScreenState:
  Widget _buildProductCard(Product p) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(product: p),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,            // cao vừa đủ nội dung
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Danh mục: ${p.categoryName}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('Thương hiệu: ${p.brandName}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('Giá: ${formatPrice((p.lowestPrice ?? 0).toDouble())}',
                  style: const TextStyle(fontSize: 14, color: Colors.green)),
              const SizedBox(height: 8),
              Text('Kho: ${p.stock}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),  // cách trước ButtonBar
              Text('Biến thể: ${p.variantCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 0,         // khoảng cách giữa các button
                overflowSpacing: 0, // khi overflow thì khoảng cách
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _openDetail(product: p),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Xác nhận xoá'),
                          content: Text('Bạn có chắc muốn xoá sản phẩm "${p.name}" không?'),
                          actions: [
                            TextButton(onPressed: () => context.pop(false), child: const Text('Huỷ')),
                            ElevatedButton(onPressed: () => context.pop(true), child: const Text('Xoá')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await ProductService.deleteProduct(p.id!);
                          setState(() {
                            _allProducts.remove(p);
                            _onSearch();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xoá sản phẩm.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi xoá sản phẩm: $e')),
                          );
                        }
                      }
                    },
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Khi màn hình nhỏ (mobile): hiển thị card list
  Widget _buildProductListMobile() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              int crossCount =
              (totalWidth / 250).floor().clamp(1, 6);
              final itemWidth =
                  (totalWidth - (crossCount - 1) * 16) /
                      crossCount;

              return SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(vertical: 20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _filteredProducts.map((p) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildProductCard(p),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Khi màn hình to (desktop/tablet): hiển thị DataTable
  Widget _buildProductTableDesktop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 300;

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: screenWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                            (states) => Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                      ),
                      columns: const [
                        DataColumn(label: Text('Tên sản phẩm')),
                        DataColumn(label: Text('Thương hiệu')),
                        DataColumn(label: Text('Danh mục')),
                        DataColumn(label: Text('Giá')),
                        DataColumn(label: Text('Số lượng')),
                        DataColumn(label: Text('Thao tác')),
                      ],
                      rows: _filteredProducts.map((p) {
                        final priceText = p.lowestPrice != null
                            ? formatPrice((p.lowestPrice!).toDouble())
                            : '—';
                        final brandName = _brands
                            .firstWhere((b) => b.id == p.brandId,
                            orElse: () => Brand(id: '', name: '—'))
                            .name;
                        final categoryName = _categories
                            .firstWhere((c) => c.id == p.categoryId,
                            orElse: () => Category(id: '', name: '—'))
                            .name;

                        return DataRow(cells: [
                          DataCell(Text(p.name)),
                          DataCell(Text(brandName)),
                          DataCell(Text(categoryName)),
                          DataCell(Text(priceText)),
                          DataCell(Text(p.stock.toString())),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openDetail(product: p),
                                tooltip: 'Chỉnh sửa',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Xác nhận xoá'),
                                      content: Text('Bạn có chắc muốn xoá sản phẩm "${p.name}" không?'),
                                      actions: [
                                        TextButton(onPressed: () => context.pop(false), child: const Text('Huỷ')),
                                        ElevatedButton(onPressed: () => context.pop(true), child: const Text('Xoá')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ProductService.deleteProduct(p.id!);
                                      setState(() {
                                        _allProducts.remove(p);
                                        _onSearch();
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xoá sản phẩm.')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi xoá sản phẩm: $e')),
                                      );
                                    }
                                  }
                                },
                                tooltip: 'Xóa',
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Thanh cuộn ngang luôn hiển thị ở dưới cùng
        SizedBox(
          height: 12, // độ dày của thanh scroll
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (notif) =>
            notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              // một container rỗng để Scrollbar "có gì mà vẽ"
              child: SizedBox(width: screenWidth),
            ),
          ),
        ),
      ],
    );
  }
}
