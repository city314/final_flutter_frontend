import 'dart:convert';

import 'package:cpmad_final/models/variant.dart';
import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import '../../models/product.dart';
import '../../models/review.dart';
import '../../models/selectedproduct.dart';
import '../../service/AnalysisAI.dart';
import '../../service/CartService.dart';
import '../../service/ProductService.dart';
import '../../service/UserService.dart';
import '../../service/WebSocketService.dart';
import 'CustomNavbar.dart';
import '../../utils/format_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetailScreen> {
  // Danh sách danh mục và thương hiệu mẫu
  final Map<String, List<String>> categoryBrands = {
    'Laptop': ['Asus', 'Dell', 'HP', 'Apple'],
    'PC': ['Acer', 'Lenovo', 'MSI'],
    'Tai nghe': ['Sony', 'JBL', 'Sennheiser'],
    'Màn hình': ['Samsung', 'LG', 'ViewSonic'],
    'Bàn phím': ['Logitech', 'Razer'],
    'Chuột': ['Logitech', 'Razer', 'Fuhlen'],
    'Phụ kiện': ['Anker', 'Xiaomi'],
  };

  int selectedVariantIndex = 0;

  final Map<String, IconData> categoryIcons = {
    'Laptop': Icons.laptop,
    'PC': Icons.desktop_windows,
    'Tai nghe': Icons.headphones,
    'Màn hình': Icons.monitor,
    'Bàn phím': Icons.keyboard,
    'Chuột': Icons.mouse,
    'Phụ kiện': Icons.extension,
  };

  final Map<String, String> brandLogos = {
    'Asus': 'assets/images/brand/asus.png',
    'Dell': 'assets/images/brand/dell.png',
    'HP': 'assets/images/brand/hp.png',
    'Apple': 'assets/images/brand/apple.png',
    'Acer': 'assets/images/brand/acer.png',
    'Lenovo': 'assets/images/brand/lenovo.png',
    'MSI': 'assets/images/brand/msi.png',
    'Sony': 'assets/images/brand/sony.png',
    'JBL': 'assets/images/brand/jbl.png',
    'Sennheiser': 'assets/images/brand/sennheiser.png',
    'Samsung': 'assets/images/brand/samsung.png',
    'LG': 'assets/images/brand/lg.png',
    'ViewSonic': 'assets/images/brand/viewsonic.png',
    'Logitech': 'assets/images/brand/logitech.png',
    'Razer': 'assets/images/brand/razer.png',
    'Fuhlen': 'assets/images/brand/fuhlen.png',
    'Anker': 'assets/images/brand/anker.png',
    'Xiaomi': 'assets/images/brand/xiaomi.png',
  };

  int quantity = 1;
  int _currentImage = 0;

  final PageController _imagePageController = PageController();

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  Product? _product;
  bool _isLoading = true;
  // Thêm biến thể sản phẩm
  late List<Variant> _variants = [];
  Variant? selectedVariant;

  final socketService = WebSocketService();
  List<Review> reviews = [];
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  Map<String, dynamic>? userInfo;
  int _visibleReviewCount = 5;
  int _reviewCount = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
    socketService.connect((newReview) {
      if (!mounted) return;
      if (!reviews.any((r) =>
      r.userId == newReview.userId &&
          r.comment == newReview.comment &&
          (r.timeCreate.difference(newReview.timeCreate).inSeconds).abs() < 2)) {
        setState(() => reviews.insert(0, newReview));
      }
    });

    if (CurrentUser().isLogin) {
      _loadUserInfo();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadReviews() async {
    try {
      final fetched = await ProductService.fetchReviews(widget.productId);
      setState(() {
        reviews = fetched;
        _reviewCount = fetched.length;
        _visibleReviewCount = 5;
        _averageRating = _reviewCount == 0
            ? 0.0
            : fetched.map((r) => r.rating).reduce((a, b) => a + b) / _reviewCount;
      });
    } catch (e) {
      debugPrint('Danh sách rỗng');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final data = await UserService.fetchUserByEmail(CurrentUser().email ?? '');
      setState(() => userInfo = data);
    } catch (e) {
      print('Lỗi lấy user info: $e');
    }
  }

  void _loadProduct() async {
    final fetched = await ProductService.fetchProductById(widget.productId);
    final fetchedVariants = await ProductService.fetchVariantsByProduct(widget.productId);

    setState(() {
      _product = fetched;
      _variants = fetchedVariants;
      // selectedVariant = fetchedVariants.isNotEmpty ? fetchedVariants[0] : null;
      _isLoading = false;
    });
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh Mục Sản Phẩm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...categoryBrands.entries.map((entry) => ExpansionTile(
                      title: Row(
                        children: [
                          Icon(categoryIcons[entry.key] ?? Icons.category),
                          const SizedBox(width: 12),
                          Text(entry.key),
                        ],
                      ),
                      children: entry.value.map((brand) => ListTile(
                        leading: brandLogos[brand] != null
                            ? Image.asset(brandLogos[brand]!, width: 24, height: 24)
                            : null,
                        title: Text(brand),
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 32),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Xử lý khi chọn danh mục
                        },
                      )).toList(),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_product == null) {
      return const Center(child: Text('Không tìm thấy sản phẩm'));
    }
    return Scaffold(
      appBar: CustomNavbar(
        onHomeTap: () {},
        onCategoriesTap: () {},
        onCartTap: () { context.go('/account/cart'); },
        onRegisterTap: () {},
        onLoginTap: () {},
        onSupportTap: () {},
        onSearch: (value) {},
      ),
      body: isAndroid ? _buildAndroidLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildAndroidLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar và nút danh mục
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _showCategoryBottomSheet,
                  icon: const Icon(Icons.category),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          // Tên sản phẩm + đánh giá
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVariant?.variantName ?? _product!.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                            (index) => Icon(
                          index < _averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('(${_reviewCount} đánh giá)',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Slide ảnh sản phẩm
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _imagePageController,
                  itemCount: (selectedVariant?.images ?? _product!.images).length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageBytes = getImageBytes((selectedVariant?.images ?? _product!.images)[index] as Map<String, String>);
                    return imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.contain)
                        : const Icon(Icons.broken_image);
                  },
                ),
                // Nút chuyển trái
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black54, size: 32),
                    onPressed: () {
                      if (_currentImage > 0) {
                        _imagePageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _imagePageController.jumpToPage((selectedVariant?.images ?? _product!.images).length - 1);
                      }
                    },
                  ),
                ),
                // Nút chuyển phải
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black54, size: 32),
                    onPressed: () {
                      if (_currentImage < (selectedVariant?.images ?? _product!.images).length - 1) {
                        _imagePageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _imagePageController.jumpToPage(0);
                      }
                    },
                  ),
                ),
                // Indicator
                Positioned(
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate((selectedVariant?.images ?? _product!.images).length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentImage == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImage == index ? Colors.blueAccent : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Giá + logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedVariant?.variantName ?? _product!.name,
                  semanticsLabel: formatPrice(_variants[selectedVariantIndex].sellingPrice),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Row(
                  children: [
                    Text(
                      _product!.brandName ?? '',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Thêm phần chọn biến thể
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      _variants.length,
                          (index) {
                        final variant = _variants[index];
                        final firstImage = variant.images.isNotEmpty ? variant.images[0]['base64'] : null;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedVariantIndex = index;
                              selectedVariant = _variants[index];
                              _currentImage = 0;
                              _imagePageController.jumpToPage(0);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedVariantIndex == index ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedVariantIndex == index ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                firstImage != null
                                    ? Image.memory(base64Decode(firstImage), width: 40, height: 40, fit: BoxFit.cover)
                                    : const Icon(Icons.image, size: 40),
                                const SizedBox(width: 8),
                                Text(
                                  variant.variantName,
                                  style: TextStyle(
                                    color: selectedVariantIndex == index ? Colors.blue : Colors.black,
                                    fontWeight: selectedVariantIndex == index ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Điều chỉnh số lượng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (quantity > 1) quantity--;
                    });
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nút thêm giỏ hàng và mua ngay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedVariant == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn 1 mẫu sản phẩm')),
                        );
                        return;
                      };
                      try {
                        final cartExists = await CartService.isCartCreated();
                        final userId = await CartService.getEffectiveUserId();
                        if (!cartExists) {
                          await CartService.createCartAndAddItem(
                            userId: userId,
                            variantId: selectedVariant!.id!,
                            quantity: quantity,
                          );
                        } else {
                          await CartService.updateCartItem(
                            userId: userId,
                            variantId: selectedVariant!.id!,
                            quantity: quantity,
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Thêm giỏ hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedVariant == null) return;
                      final selectedProduct = SelectedProduct(
                        variant: selectedVariant!,
                        quantity: quantity,
                        discount: _product!.discountPercent ?? 0,
                      );
                      context.goNamed(
                        'cartsummary',
                        extra: {
                          'items': [
                            SelectedProduct(
                              variant: selectedVariant!,
                              quantity: quantity,
                              discount: _product?.discountPercent ?? 0,
                            ).toJson()
                          ]
                        },
                      );
                    },
                    child: const Text('Mua ngay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Mô tả sản phẩm và cấu hình biến thể (nếu có)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mô tả sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _product!.description,
                  style: const TextStyle(fontSize: 15),
                ),
                if (selectedVariant != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Cấu hình biến thể',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Màu sắc:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(selectedVariant!.color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Số lượng tồn:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(selectedVariant!.stock.toString()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Thông số khác:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...selectedVariant!.attributes
                      .split('\n')
                      .map((line) => Text('- $line', style: const TextStyle(fontSize: 14)))
                      .toList(),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Đánh giá khách hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá của khách hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Danh sách đánh giá mẫu
                Column(
                  children: [
                    ...reviews
                        .take(_visibleReviewCount)
                        .map((review) => _buildReview(
                      avatar: review.avatar ?? '',
                      name: review.userName ?? '',
                      rating: review.rating.toInt(),
                      comment: review.comment,
                    ))
                        .toList(),
                    if (_visibleReviewCount < reviews.length)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _visibleReviewCount += 10;
                            });
                          },
                          child: const Text("Tải thêm bình luận"),
                        ),
                      ),
                  ],
                ),

              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Gửi đánh giá:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(hintText: "Viết đánh giá..."),
                ),
                const SizedBox(height: 8),
                if (CurrentUser().isLogin) ...[
                  const SizedBox(height: 8),
                  const Text("Chọn số sao:"),
                  Row(
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(index < _rating ? Icons.star : Icons.star_border),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    )),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text("Bạn cần đăng nhập để đánh giá sao.", style: TextStyle(color: Colors.orange)),
                ],
                ElevatedButton(
                  onPressed: () {
                    final isLoggedIn = CurrentUser().isLogin;
                    final review = Review(
                      productId: widget.productId,
                      userId: isLoggedIn ? userInfo!['email'] ?? '' : '',
                      userName: isLoggedIn ? userInfo!['name'] ?? 'Ẩn danh' : 'Ẩn danh',
                      rating: isLoggedIn ? _rating : 0,
                      comment: _commentController.text,
                      timeCreate: DateTime.now(),
                      avatar: isLoggedIn ? userInfo!['avatar'] : ''
                    );

                    ProductService.postReview(review);
                    socketService.sendReview(review);

                    _commentController.clear();
                    setState(() => _rating = 0);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isLoggedIn ? 'Gửi đánh giá thành công' : 'Gửi bình luận thành công')),
                    );
                  },
                  child: const Text("Gửi đánh giá"),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Footer
          Container(
            width: double.infinity,
            color: const Color(0xFF43A7C6),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'CỬA HÀNG LAPIZONE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.phone, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text('SĐT: 0123 456 789', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.location_on, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text('Địa chỉ: Tân Phong, Quận 7, TP HCM', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.email, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text('Email: info@lapizone.vn', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.support_agent, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text('Hotline: 1800 1234', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar danh mục
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF9FE),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: ListView(
            children: [
              const Text('Tất Cả Danh Mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...categoryBrands.entries.map((entry) => ExpansionTile(
                title: Text(entry.key),
                leading: Icon(categoryIcons[entry.key] ?? Icons.category),
                children: entry.value.map((brand) => ListTile(
                  leading: brandLogos[brand] != null
                      ? Image.asset(brandLogos[brand]!, width: 24, height: 24)
                      : null,
                  title: Text(brand),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 32),
                  onTap: () {},
                )).toList(),
              )),
            ],
          ),
        ),
        // Nội dung chi tiết sản phẩm
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVariant?.variantName ?? _product!.name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                            (index) => Icon(
                          index < _averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('(${_reviewCount} đánh giá)',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                // Ảnh + giá + logo + nút
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slide ảnh sản phẩm
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Nút chuyển trái
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.black54, size: 32),
                              onPressed: () {
                                if (_currentImage > 0) {
                                  _imagePageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                } else {
                                  _imagePageController.jumpToPage((selectedVariant?.images ?? _product!.images).length - 1);
                                }
                              },
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PageView.builder(
                              controller: _imagePageController,
                              itemCount: (selectedVariant?.images ?? _product!.images).length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imageBytes = getImageBytes((selectedVariant?.images ?? _product!.images)[index] as Map<String, String>);
                                return imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                                    : const Icon(Icons.broken_image);
                              },
                            ),
                          ),
                          // Nút chuyển phải
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.black54, size: 32),
                              onPressed: () {
                                if (_currentImage < (selectedVariant?.images ?? _product!.images).length - 1) {
                                  _imagePageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                } else {
                                  _imagePageController.jumpToPage(0);
                                }
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate((selectedVariant?.images ?? _product!.images).length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentImage == index ? 16 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImage == index ? Colors.blueAccent : Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Giá + logo + nút
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _product!.brandName ?? '',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            formatPrice((selectedVariant?.sellingPrice ?? _product!.lowestPrice ?? 0).toDouble()),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 24),
                          // Thêm phần chọn biến thể
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    _variants.length,
                                        (index) {
                                      final variant = _variants[index];
                                      final firstImage = variant.images.isNotEmpty ? variant.images[0]['base64'] : null;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedVariantIndex = index;
                                            selectedVariant = _variants[index];
                                            _currentImage = 0;
                                            _imagePageController.jumpToPage(0);
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: selectedVariantIndex == index ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: selectedVariantIndex == index ? Colors.blue : Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              firstImage != null
                                                  ? Image.memory(base64Decode(firstImage), width: 40, height: 40, fit: BoxFit.cover)
                                                  : const Icon(Icons.image, size: 40),
                                              const SizedBox(width: 8),
                                              Text(
                                                variant.variantName,
                                                style: TextStyle(
                                                  color: selectedVariantIndex == index ? Colors.blue : Colors.black,
                                                  fontWeight: selectedVariantIndex == index ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Điều chỉnh số lượng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    if (quantity > 1) quantity--;
                                  });
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (selectedVariant == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng chọn 1 mẫu sản phẩm')),
                                    );
                                    return;
                                  };
                                  try {
                                    final cartExists = await CartService.isCartCreated();
                                    final userId = await CartService.getEffectiveUserId();
                                    print(cartExists);
                                    if (!cartExists) {
                                      await CartService.createCartAndAddItem(
                                        userId: userId,
                                        variantId: selectedVariant!.id!,
                                        quantity: quantity,
                                      );
                                    } else {
                                      await CartService.updateCartItem(
                                        userId: userId,
                                        variantId: selectedVariant!.id!,
                                        quantity: quantity,
                                      );
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text('Thêm giỏ hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedVariant == null) return;
                                  final selectedProduct = SelectedProduct(
                                    variant: selectedVariant!,
                                    quantity: quantity,
                                    discount: _product!.discountPercent ?? 0,
                                  );
                                  context.goNamed(
                                    'cartsummary',
                                    extra: {
                                      'items': [
                                        SelectedProduct(
                                          variant: selectedVariant!,
                                          quantity: quantity,
                                          discount: _product?.discountPercent ?? 0,
                                        ).toJson()
                                      ]
                                    },
                                  );
                                },
                                child: const Text('Mua ngay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Mô tả sản phẩm
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô tả sản phẩm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _product!.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                      if (selectedVariant != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Cấu hình biến thể',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Màu sắc:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(selectedVariant!.color),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Số lượng tồn:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(selectedVariant!.stock.toString()),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Thông số khác:', style: TextStyle(fontWeight: FontWeight.w600)),
                        ...selectedVariant!.attributes
                            .split('\n')
                            .map((line) => Text('- $line', style: const TextStyle(fontSize: 14)))
                            .toList(),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Đánh giá khách hàng
                const Text(
                  'Đánh giá của khách hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Danh sách đánh giá mẫu
                Column(
                  children: [
                    ...reviews
                        .take(_visibleReviewCount)
                        .map((review) => _buildReview(
                      avatar: review.avatar ?? '',
                      name: review.userName ?? '',
                      rating: review.rating.toInt(),
                      comment: review.comment,
                    ))
                        .toList(),
                    if (_visibleReviewCount < reviews.length)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _visibleReviewCount += 10;
                            });
                          },
                          child: const Text("Tải thêm bình luận"),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Gửi đánh giá:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(hintText: "Viết đánh giá..."),
                      ),
                      const SizedBox(height: 8),
                      if (CurrentUser().isLogin) ...[
                        const SizedBox(height: 8),
                        const Text("Chọn số sao:"),
                        Row(
                          children: List.generate(5, (index) => IconButton(
                            icon: Icon(index < _rating ? Icons.star : Icons.star_border),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          )),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text("Bạn cần đăng nhập để đánh giá sao.", style: TextStyle(color: Colors.orange)),
                      ],
                      ElevatedButton(
                        onPressed: () async {
                          final isLoggedIn = CurrentUser().isLogin;
                          final reviewText = _commentController.text;
                          final aiResult = await getSentimentAnalysis(reviewText);

                          final review = Review(
                              productId: widget.productId,
                              userId: isLoggedIn ? userInfo!['email'] ?? '' : '',
                              userName: isLoggedIn ? userInfo!['name'] ?? 'Ẩn danh' : 'Ẩn danh',
                              rating: isLoggedIn ? _rating : 0,
                              comment: reviewText + '\n\n🤖 AI Nhận xét: ${aiResult['sentiment']}\n👉 ${aiResult['explanation']}',
                              timeCreate: DateTime.now(),
                              avatar: isLoggedIn ? userInfo!['avatar'] : ''
                          );

                          ProductService.postReview(review);
                          socketService.sendReview(review);

                          _commentController.clear();
                          setState(() => _rating = 0);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isLoggedIn ? 'Gửi đánh giá thành công' : 'Gửi bình luận thành công')),
                          );
                        },
                        child: const Text("Gửi đánh giá"),
                      )
                    ],
                  ),
                ),
                // Footer
                Container(
                  width: double.infinity,
                  color: const Color(0xFF43A7C6),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'CỬA HÀNG LAPIZONE',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.phone, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text('SĐT: 0123 456 789', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.location_on, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text('Địa chỉ: Tân Phong, Quận 7, TP HCM', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.email, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text('Email: info@lapizone.vn', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.support_agent, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text('Hotline: 1800 1234', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildReview({
    required String avatar,
    required String name,
    required int rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: avatar.isNotEmpty
                ? MemoryImage(base64Decode(avatar))
                : AssetImage('images/avt_default.png'),
            radius: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        rating,
                            (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: comment.split('\n').map((line) {
                      final trimmed = line.trim();
                      if (trimmed.startsWith('🤖')) {
                        return TextSpan(
                          text: '$line\n',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.deepPurple,
                          ),
                        );
                      } else if (trimmed.startsWith('👉')) {
                        return TextSpan(
                          text: '$line\n',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        );
                      } else {
                        return TextSpan(
                          text: '$line\n',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        );
                      }
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? getImageBytes(Map<String, String> image) {
    final base64Str = image['base64'];
    if (base64Str != null) {
      try {
        return base64Decode(base64Str);
      } catch (e) {
        debugPrint('Lỗi decode base64: $e');
      }
    }
    return null;
  }

  static Color? parseColor(String? colorName) {
    if (colorName == null) return null;
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey, // US/UK spelling
      'brown': Colors.brown,
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'amber': Colors.amber,
      'indigo': Colors.indigo,
      'lime': Colors.lime,
    };

    return colorMap[colorName.toLowerCase()];
  }
}