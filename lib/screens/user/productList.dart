import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../service/ProductService.dart';
import 'CustomNavbar.dart';
import '../../utils/format_utils.dart';
import '../../service/CartService.dart';
import '../../models/variant.dart';
import '../../pattern/current_user.dart';

class ProductList extends StatefulWidget {
  final String categoryId;
  const ProductList({super.key, required this.categoryId});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = false;

  // Dữ liệu mẫu cho filter
  final List<Category> categories = [];
  final List<Brand> brands = [];
  final List<String> priceRanges = [
    'Dưới 5 triệu', '5-10 triệu', '10-20 triệu', 'Trên 20 triệu'
  ];
  final List<String> ratingRanges = [
    '5 sao', '4 sao trở lên', '3 sao trở lên', '2 sao trở lên', '1 sao trở lên'
  ];
  List<String> selectedCategories = [];
  List<String> selectedCategoriesId = [];
  List<String> selectedBrands = [];
  List<String> selectedBrandsId = [];
  String? selectedPrice;
  String? selectedRating;
  String sortType = 'Mới nhất';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final cats = await ProductService.fetchAllCategory();
      final brs = await ProductService.fetchAllBrand();
      final products = await ProductService.fetchProductsPanigation(
        categoryId: widget.categoryId,
      );

      setState(() {
        categories.clear();
        categories.addAll(cats);
        brands.clear();
        brands.addAll(brs);
        _products = products;
      });
    } catch (e) {
      print("Load data error: $e");
    }
  }

  int _skip = 0;

  void _loadMoreIfNeeded() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !_isLoading) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() async {
    setState(() => _isLoading = true);

    try {
      _skip += 20;
      final moreProducts = await ProductService.fetchProductsPanigation(
        categoryId: widget.categoryId,
        price: selectedPrice,
        sort: sortType,
        skip: _skip,
        search: _searchCtrl.text,
      );
      setState(() {
        _products.addAll(moreProducts);
      });
    } catch (e) {
      print("Pagination error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      appBar: CustomNavbar(
        onHomeTap: () { context.go('/home'); },
        onCategoriesTap: () {},
        onCartTap: () {},
        onRegisterTap: () {},
        onLoginTap: () {},
        onSupportTap: () {},
        onSearch: (value) {
          _searchCtrl.text = value;
          _applyFilters(); // ✅ chỉ gọi khi user nhấn icon tìm trên navbar
        },
      ),
      body: isAndroid
          ? Column(
              children: [
                // Search bar dưới navbar cho Android
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        onPressed: () {
                          _applyFilters(); // chỉ tìm khi bấm
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => _buildFilterSheet(),
                          );
                        },
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Bộ lọc'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          value: sortType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
                            DropdownMenuItem(value: 'Giá tăng dần', child: Text('Giá tăng dần')),
                            DropdownMenuItem(value: 'Giá giảm dần', child: Text('Giá giảm dần')),
                            DropdownMenuItem(value: 'Sắp xếp theo tên từ A-Z', child: Text('Sắp xếp theo tên từ A-Z')),
                            DropdownMenuItem(value: 'Sắp xếp theo tên từ Z-A', child: Text('Sắp xếp theo tên từ Z-A')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              sortType = v!;
                              _applyFilters(); // Gọi lại filter khi đổi sort
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_products[index]);
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar cũ
                Container(
                  width: 270,
                  color: Colors.grey[50],
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: ListView(
                    children: [
                      const Text('Tất Cả Danh Mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      for (final c in categories)
                        ListTile(
                          title: Text(c.name),
                          dense: true,
                          contentPadding: const EdgeInsets.only(left: 8),
                          onTap: () {},
                        ),
                      const Divider(height: 32),
                      const Text('BỘ LỌC TÌM KIẾM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text('Theo Danh Mục', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...categories.map((cat) => CheckboxListTile(
                        value: selectedCategories.contains(cat.name),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedCategories.add(cat.name);
                              selectedCategoriesId.add(cat.id!);
                            } else {
                              selectedCategories.remove(cat.name);
                              selectedCategoriesId.remove(cat.id);
                            }
                          });
                        },
                        title: Text(cat.name),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                      const SizedBox(height: 8),
                      const Text('Theo Thương Hiệu', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...brands.map((brand) => CheckboxListTile(
                        value: selectedBrands.contains(brand.name),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedBrands.add(brand.name);
                              selectedBrandsId.add(brand.id!);
                            } else {
                              selectedBrands.remove(brand.name);
                              selectedBrandsId.remove(brand.id);
                            }
                          });
                        },
                        title: Text(brand.name),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                      const SizedBox(height: 8),
                      const Text('Giá sản phẩm', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...priceRanges.map((price) => RadioListTile<String>(
                        value: price,
                        groupValue: selectedPrice,
                        onChanged: (v) {
                          setState(() {
                            selectedPrice = v;
                          });
                        },
                        title: Text(price),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                      const SizedBox(height: 8),
                      const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...ratingRanges.map((rating) => RadioListTile<String>(
                        value: rating,
                        groupValue: selectedRating,
                        onChanged: (v) {
                          setState(() {
                            selectedRating = v;
                          });
                        },
                        title: Row(
                          children: [
                            Text(rating),
                            const SizedBox(width: 8),
                            ...List.generate(
                              int.parse(rating[0]),
                              (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                            ),
                          ],
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Main content cũ
                Expanded(
                  child: Column(
                    children: [
                      // Filter bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Text('Sắp xếp:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: sortType,
                              items: const [
                                DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
                                DropdownMenuItem(value: 'Giá tăng dần', child: Text('Giá tăng dần')),
                                DropdownMenuItem(value: 'Giá giảm dần', child: Text('Giá giảm dần')),
                                DropdownMenuItem(value: 'Sắp xếp theo tên từ A-Z', child: Text('Sắp xếp theo tên từ A-Z')),
                                DropdownMenuItem(value: 'Sắp xếp theo tên từ Z-A', child: Text('Sắp xếp theo tên từ Z-A')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  sortType = v!;
                                  _applyFilters(); // Gọi lại filter khi đổi sort
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3 / 4,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_products[index]);
                          },
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Log dữ liệu product để debug
    try {
      print(product.toJson());
    } catch (e) {
      print(product);
    }

    String? base64Str;
    if (product.images != null && product.images!.isNotEmpty) {
      final img = product.images!.first;
      if (img != null && img['base64'] != null && img['base64'] is String) {
        base64Str = img['base64'] as String;
      }
    }
    Uint8List? imageBytes;
    try {
      if (base64Str != null && base64Str.isNotEmpty) {
        // Loại bỏ prefix nếu có (data:image/png;base64,...)
        imageBytes = base64Decode(base64Str.split(',').last);
      }
    } catch (e) {
      print('Lỗi decode base64: $e, base64Str: $base64Str');
      imageBytes = null;
    }

    return GestureDetector(
      onTap: () {
        context.go('/products/${product.id}');
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                    : const Icon(Icons.broken_image),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice((product.lowestPrice ?? 0).toDouble()),
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 4),
                    if (product.averageRating != null && product.averageRating! > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            product.averageRating!.round(),
                                (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                          ),
                          if (product.averageRating! % 1 != 0)
                            const Icon(Icons.star_half, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            product.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BỘ LỌC TÌM KIẾM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            
            // Lọc theo danh mục
            const Text('Theo Danh Mục', style: TextStyle(fontWeight: FontWeight.w500)),
            ...categories.map((cat) => CheckboxListTile(
              value: selectedCategories.contains(cat.name),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedCategories.add(cat.name);
                    selectedCategoriesId.add(cat.id!);
                  } else {
                    selectedCategories.remove(cat.name);
                    selectedCategoriesId.remove(cat.id);
                  }
                });
              },
              title: Text(cat.name),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 8),
            
            // Lọc theo thương hiệu
            const Text('Theo Thương Hiệu', style: TextStyle(fontWeight: FontWeight.w500)),
            ...brands.map((brand) => CheckboxListTile(
              value: selectedBrands.contains(brand.name),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedBrands.add(brand.name);
                    selectedBrandsId.add(brand.id!);
                  } else {
                    selectedBrands.remove(brand.name);
                    selectedBrandsId.remove(brand.id);
                  }
                });
              },
              title: Text(brand.name),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 8),
            
            // Lọc theo giá
            const Text('Giá sản phẩm', style: TextStyle(fontWeight: FontWeight.w500)),
            ...priceRanges.map((price) => RadioListTile<String>(
              value: price,
              groupValue: selectedPrice,
              onChanged: (v) {
                setState(() {
                  selectedPrice = v;
                });
              },
              title: Text(price),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 8),
            
            // Lọc theo đánh giá
            const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w500)),
            ...ratingRanges.map((rating) => RadioListTile<String>(
              value: rating,
              groupValue: selectedRating,
              onChanged: (v) {
                setState(() {
                  selectedRating = v;
                });
              },
              title: Row(
                children: [
                  Text(rating),
                  const SizedBox(width: 8),
                  ...List.generate(
                    int.parse(rating[0]),
                    (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                ],
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() async {
    setState(() {
      _isLoading = true;
      _products.clear();
      _skip = 0;
    });

    try {
      final filtered = await ProductService.fetchProductsPanigation(
        categoryId: selectedCategoriesId.join(','), // nhiều danh mục
        brandId: selectedBrandsId.join(','), // nhiều brand
        price: selectedPrice,
        rating: selectedRating,
        sort: sortType,
        skip: 0,
        search: _searchCtrl.text,
      );
      setState(() {
        _products = filtered;
      });
    } catch (e) {
      print("Filter error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

}
