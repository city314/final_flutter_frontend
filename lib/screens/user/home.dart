import 'dart:convert';
import 'dart:typed_data';

import 'package:cpmad_final/models/category.dart';
import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../service/ProductService.dart';
import '../../utils/format_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _allLaptops = List.generate(6, (index) => 'Laptop Model ${index + 1}');
  List<String> _filteredLaptops = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int hotSaleDisplayCount = 5;
  int newProductDisplayCount = 5;
  int promotionDisplayCount = 5;
  String _searchKeyword = '';
  late Future<Map<String, List<Product>>> productSummary;
  final List<String> _sliderImages = [
    'assets/images/slider/slider1.png',
    'assets/images/slider/slider5.png',
    'assets/images/slider/slider2.png',
  ];
  List<Product> hotSaleProducts = [];
  List<Product> newProducts = [];
  List<Product> promotionProducts = [];
  List<Category> categories = [];
  Map<String, List<Product>> _categoryProducts = {};
  List<String?> categoryIds = [];
  List<String?> categoryName = [];
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    ProductService().fetchProductSummary().then((data) {
      if (!mounted) return;
      setState(() {
        hotSaleProducts = data['bestSellers'] ?? [];
        newProducts = data['newProducts'] ?? [];
        promotionProducts = data['promotions'] ?? [];
      });
    }).catchError((e) {
      // Có thể show SnackBar hoặc in log nếu cần
      debugPrint('Lỗi khi lấy sản phẩm: $e');
    });
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final fetched = await ProductService.fetchAllCategory();
      final ids = fetched.take(7).map((c) => c.id).toList();
      final name = fetched.take(7).map((c) => c.name).toList();
      if (!mounted) return;
      setState(() {
        categories = fetched;
        categoryIds = ids;
        categoryName = name;
      });

      for (String? id in ids) {
        final products = await ProductService().fetchProductsByCategory(id!);
        if (!mounted) return;
        setState(() {
          _categoryProducts[id] = products;
        });
      }

    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Uint8List? getImageBytes(Map<String, dynamic> image) {
    final base64Str = image['base64'];
    if (base64Str is String) {
      try {
        return base64Decode(base64Str);
      } catch (e) {
        debugPrint('Lỗi decode base64: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMobile = screenSize.width < 400;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      appBar: CustomNavbar(
        onHomeTap: () {
          context.go('/home');
        },
        onCategoriesTap: () {
          context.go('/products');
        },
        onCartTap: () {
          context.go('/account/cart');
        },
        onRegisterTap: () {
          context.go('/signup');
        },
        onLoginTap: () {
          context.go('/');
        },
        onSupportTap: () {
          context.goNamed('admin_chat', extra: 'admin@gmail.com');
        },
        onProfileTap: isAndroid ? () {
          context.go('/account');
        } : null,
        onLogoutTap: isAndroid ? () {
          setState(() {
            CurrentUser().logout();
          });
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng xuất')),
          );
        } : null,
        onSearch: (value) {
          setState(() {
            _searchKeyword = value.toLowerCase();
            _filteredLaptops = _allLaptops
                .where((laptop) => laptop.toLowerCase().contains(_searchKeyword))
                .toList();
          });
        },
        // isLoggedIn: isAndroid ? isLoggedIn : false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isAndroid)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchKeyword = value.toLowerCase();
                      _filteredLaptops = _allLaptops
                          .where((laptop) => laptop.toLowerCase().contains(_searchKeyword))
                          .toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    suffixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            SizedBox(
              height: isMobile ? 200 : (isSmallScreen ? 300 : 450),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _sliderImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 16,
                          vertical: isMobile ? 8 : 16,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            _sliderImages[index],
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                  ),
                  // Nút điều hướng trái
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                      onPressed: () {
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Nếu đang ở slide đầu, chuyển về slide cuối
                          _pageController.jumpToPage(_sliderImages.length - 1);
                          setState(() {
                            _currentPage = _sliderImages.length - 1;
                          });
                        }
                      },
                    ),
                  ),
                  // Nút điều hướng phải
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                      onPressed: () {
                        if (_currentPage < _sliderImages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Nếu đang ở slide cuối, chuyển về slide đầu
                          _pageController.jumpToPage(0);
                          setState(() {
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ),
                  // Indicator
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_sliderImages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.blueAccent : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
              child: SizedBox(
                height: isMobile ? 60 : (isSmallScreen ? 80 : 120),
                child: Center(
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => SizedBox(width: isMobile ? 8 : 18),
                    itemBuilder: (context, index) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            // TODO: Xử lý khi bấm vào danh mục
                          },
                          child: Container(
                            width: isMobile ? 60 : (isSmallScreen ? 80 : 100),
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon(
                                //   categories[index]['icon'],
                                //   size: isMobile ? 20 : (isSmallScreen ? 24 : 36),
                                //   color: Colors.blueAccent
                                // ),
                                SizedBox(height: isMobile ? 4 : 8),
                                Flexible(
                                  child: Text(
                                    categories[index].name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Hot Sale
            SizedBox(height: isMobile ? 16 : 32),
            Padding(
              padding: EdgeInsets.only(left: isMobile ? 16 : 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: isMobile ? 24 : 28
                    ),
                    SizedBox(width: isMobile ? 8 : 13),
                    Text(
                      'Hot Sale',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isAndroid ? 1 : (isSmallScreen ? 2 : 5),
                  childAspectRatio: 1.1,
                  crossAxisSpacing: isAndroid ? 16 : 6,
                  mainAxisSpacing: isAndroid ? 16 : 6,
                ),
                itemCount: hotSaleProducts.length < hotSaleDisplayCount
                    ? hotSaleProducts.length
                    : hotSaleDisplayCount,
                itemBuilder: (context, index) {
                  final product = hotSaleProducts[index];
                  final imageBytes = getImageBytes(product.images.first);
                  return InkWell(
                    onTap: () {
                      context.goNamed('product_detail', pathParameters: {'id': product.id!});
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                                    : const Icon(Icons.broken_image),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              product.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 18 : 14
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatPrice((product.lowestPrice ?? 0).toDouble()),
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 16 : 13
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.description ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            if (hotSaleDisplayCount < hotSaleProducts.length)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hotSaleDisplayCount += 10;
                  });
                },
                child: const Text("Xem thêm"),
              ),
            // Sản phẩm mới
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.new_releases, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 13),
                    const Text(
                      'Sản phẩm mới',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isAndroid ? 1 : (isSmallScreen ? 2 : 5),
                  childAspectRatio: 1.1,
                  crossAxisSpacing: isAndroid ? 16 : 6,
                  mainAxisSpacing: isAndroid ? 16 : 6,
                ),
                itemCount: newProducts.length < newProductDisplayCount
                    ? newProducts.length
                    : newProductDisplayCount,
                itemBuilder: (context, index) {
                  final product = newProducts[index];
                  final imageBytes = getImageBytes(product.images.first);
                  return InkWell(
                    onTap: () {
                      context.goNamed('product_detail', pathParameters: {'id': product.id!});
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                                    : const Icon(Icons.broken_image),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatPrice((product.lowestPrice ?? 0).toDouble()),
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.description ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            if (newProductDisplayCount < newProducts.length)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    newProductDisplayCount += 10;
                  });
                },
                child: const Text("Xem thêm"),
              ),
            // Sản phẩm khuyến mãi
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange, size: 28),
                    const SizedBox(width: 13),
                    const Text(
                      'Sản phẩm khuyến mãi',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isAndroid ? 1 : (isSmallScreen ? 2 : 5),
                  childAspectRatio: 1.1,
                  crossAxisSpacing: isAndroid ? 16 : 6,
                  mainAxisSpacing: isAndroid ? 16 : 6,
                ),
                itemCount: promotionProducts.length < promotionDisplayCount
                    ? promotionProducts.length
                    : promotionDisplayCount,
                itemBuilder: (context, index) {
                  final product = promotionProducts[index];
                  final imageBytes = getImageBytes(product.images.first);
                  return InkWell(
                    onTap: () {
                      context.goNamed('product_detail', pathParameters: {'id': product.id!});
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                                    : const Icon(Icons.broken_image),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatPrice((product.lowestPrice ?? 0).toDouble()),
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.description ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            if (promotionDisplayCount < promotionProducts.length)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    promotionDisplayCount += 10;
                  });
                },
                child: const Text("Xem thêm"),
              ),
            SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(categoryIds.length, (index) {
                  final id = categoryIds[index];
                  final name = categoryName[index] ?? 'Danh mục';
                  final products = _categoryProducts[id] ?? [];
                  if (products.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 16),
                        child: Row(
                          children: [
                            Icon(Icons.category, color: Colors.indigo, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ],
                        ),
                      ),
                      ProductSection(title: name, products: products),
                    ],
                  );
                }),
              )
            ),
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
    );
  }
}

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final VoidCallback onHomeTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onCartTap;
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback onSupportTap;
  final ValueChanged<String> onSearch;

  const CustomNavbar({
    Key? key,
    this.cartItemCount = 0,
    required this.onHomeTap,
    required this.onCategoriesTap,
    required this.onCartTap,
    required this.onRegisterTap,
    required this.onLoginTap,
    this.onProfileTap,
    this.onLogoutTap,
    required this.onSearch,
    required this.onSupportTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return AppBar(
      backgroundColor: const Color(0xFF43A7C6),
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo/logo_with_title-removebg-preview.png',
            height: isMobile ? 36 : (isSmallScreen ? 48 : 70),
          ),
          SizedBox(width: isMobile ? 4 : 10),
          if (!isMobile && !isAndroid)
            Expanded(
              child: TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'search',
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  suffixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          if (!isMobile) ...[
            SizedBox(width: isSmallScreen ? 8 : 20),
            TextButton(
              onPressed: onHomeTap,
              child: const Text('HOME', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: onCategoriesTap,
              child: const Text('CATEGORIES', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: onCartTap,
              child: Row(
                children: [
                  const Text('CART', style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 4),
                  Text('$cartItemCount', style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 10),
          ],
          PopupMenuButton<int>(
            icon: Icon(Icons.account_circle, color: Colors.white, size: isMobile ? 24 : 32),
            itemBuilder: (context) => [
              if (isMobile) ...[
                PopupMenuItem(
                  value: 10,
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      onHomeTap();
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 11,
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Categories'),
                    onTap: () {
                      Navigator.pop(context);
                      onCategoriesTap();
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 12,
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Cart'),
                    onTap: () {
                      Navigator.pop(context);
                      onCartTap();
                    },
                  ),
                ),
              ],
              if (CurrentUser().isLogin) ...[
                PopupMenuItem(
                  value: 3,
                  child: ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Support'),
                    onTap: () {
                      Navigator.pop(context);
                      onSupportTap();
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 100,
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Xem profile'),
                    onTap: () {
                      context.go('/account');
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 101,
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Đăng xuất'),
                    onTap: () {
                      CurrentUser().logout();
                      context.go('/');
                      if (onLogoutTap != null) onLogoutTap!();
                    },
                  ),
                ),
              ] else ...[
                PopupMenuItem(
                  value: 1,
                  child: ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Login'),
                    onTap: () {
                      Navigator.pop(context);
                      onLoginTap();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  final String title;
  final List<Product> products;

  const ProductSection({
    Key? key,
    required this.title,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;
    String catId = '';
    // Hiển thị GridView sản phẩm trong 1 Section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isAndroid ? 1 : (isSmallScreen ? 2 : 5),
              childAspectRatio: 1.1,
              crossAxisSpacing: isAndroid ? 16 : 6,
              mainAxisSpacing: isAndroid ? 16 : 6,
            ),
            itemCount: products.length > 10 ? 10 : products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              catId = product.categoryId;
              final imageBytes = getImageBytes(product.images.first);
              return InkWell(
                onTap: () {
                  context.goNamed('product_detail', pathParameters: {'id': product.id!});
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageBytes != null
                                ? Image.memory(imageBytes, fit: BoxFit.contain)
                                : const Icon(Icons.broken_image),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          formatPrice((product.lowestPrice ?? 0).toDouble()),
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          product.description ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                context.goNamed('products', extra: catId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Xem tất cả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Uint8List? getImageBytes(Map<String, dynamic> image) {
    final base64Str = image['base64'];
    if (base64Str is String) {
      try {
        return base64Decode(base64Str);
      } catch (e) {
        debugPrint('Lỗi decode base64: $e');
      }
    }
    return null;
  }
}
