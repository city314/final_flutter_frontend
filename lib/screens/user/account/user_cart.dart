import 'dart:convert';

import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import '../../../utils/format_utils.dart';

// Models của bạn
import 'package:cpmad_final/models/cart.dart';     // Cart(id, productId, variantId, quantity…) :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}
import 'package:cpmad_final/models/product.dart';  // Product với field variants :contentReference[oaicite:2]{index=2}:contentReference[oaicite:3]{index=3}
import 'package:cpmad_final/models/variant.dart';  // Variant (variantName, color, images…) :contentReference[oaicite:4]{index=4}:contentReference[oaicite:5]{index=5}
import 'package:cpmad_final/models/category.dart';
import 'package:cpmad_final/models/brand.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/selectedproduct.dart';
import '../../../service/CartService.dart';
import '../../../service/ProductService.dart';
import '../CustomNavbar.dart';

class UserCartPage extends StatefulWidget {
  const UserCartPage({Key? key}) : super(key: key);
  @override
  _UserCartPageState createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final Set<String> _selected = {};
  Cart? _cart ;
  List<Product> _allProducts = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  List<Variant> _variants = [];
  bool isLoading = true;
  bool isLoggedIn = CurrentUser().isLogin;
  String _searchKeyword = '';
  bool get _allSelected =>
      _cart != null && _selected.length == _cart!.items.length;

  double get _totalPrice => _selected.fold(0, (sum, id) {
    final item = _cart!.items.firstWhere((i) => i.variantId == id);
    final variant = _variants.firstWhere((v) => v.id == id, orElse: () => Variant.empty());
    return sum + (variant.sellingPrice * item.quantity);
  });

  int get _totalQuantity => _selected.fold(0, (sum, id) {
    final item = _cart!.items.firstWhere((i) => i.variantId == id);
    return sum + item.quantity;
  });

  double get _totalDiscount => _selected.fold(0, (sum, id) {
    final item = _cart!.items.firstWhere((i) => i.variantId == id);
    final variant = _variants.firstWhere((v) => v.id == id, orElse: () => Variant.empty());
    final product = _allProducts.firstWhere((p) => p.id == variant.productId, orElse: () => Product.empty());
    final discountPercent = product.discountPercent ?? 0;
    return sum + (variant.sellingPrice * discountPercent / 100 * item.quantity);
  });

  List<Cart> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final id = CurrentUser().isLogin ? CurrentUser().email : cartId;
    print(id);
    final cart = await CartService.fetchCart(id ?? '');
    final products = await ProductService.fetchAllProducts();
    final variants = await ProductService.fetchAllVariants();
    // final categories = await ProductService.fetchAllCategory();
    // final brands = await ProductService.fetchAllBrand();

    setState(() {
      _cart = cart;
      _allProducts = products;
      _variants = variants;
      // _categories = categories;
      // _brands = brands;
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMobile = screenSize.width < 400;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      // offWhite background
      backgroundColor: const Color(0xFFEEF9FE),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đi tới trang Profile')),
          );
        } : null,
        onLogoutTap: isAndroid ? () {
          setState(() {
            isLoggedIn = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng xuất')),
          );
        } : null,
        onSearch: (value) {
          setState(() {
            _searchKeyword = value.toLowerCase();
          });
        },
        isLoggedIn: isAndroid ? isLoggedIn : false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCartList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Checkbox(
          value: _allSelected,
          onChanged: (value) => setState(() {
            if (value == true) {
              _selected.clear();
              _selected.addAll(_cart!.items.map((e) => e.variantId));
            } else {
              _selected.clear();
            }
          }),
        ),
        const Text('Select All'),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final userId = CurrentUser().isLogin ? CurrentUser().email! : (await SharedPreferences.getInstance()).getString('cartId') ?? '';
            for (final id in _selected) {
              await CartService.removeItem(userId, id);
            }
            setState(() {
              _cart!.items.removeWhere((e) => _selected.contains(e.variantId));
              _selected.clear();
            });
          },
        ),
      ],
    ),
  );

  Widget _buildCartList() {
    if (_cart == null || _cart!.items.isEmpty) {
      return const Center(
        child: Text(
          'Giỏ hàng trống',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _cart!.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) => _buildCartItem(_cart!.items[index]),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final variant = _variants.firstWhere((v) => v.id == item.variantId, orElse: () => Variant.empty());
    final product = _allProducts.firstWhere((p) => p.id == variant.productId, orElse: () => Product.empty());
    final imageUrl = variant.images.isNotEmpty ? variant.images[0]['base64'] ?? '' : '';
    final discountPercent = product.discountPercent ?? 0;
    final originalPrice = variant.sellingPrice;
    final discountedPrice = originalPrice * (1 - discountPercent / 100);
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _selected.contains(item.variantId),
            onChanged: (sel) => setState(() {
              if (sel == true) {
                _selected.add(item.variantId);
              } else {
                _selected.remove(item.variantId);
              }
            }),
          ),
          imageUrl.isNotEmpty
              ? Image.memory(base64Decode(imageUrl), width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 40),
        ],
      ),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${variant.variantName} | ${variant.color}'),
          if (discountPercent > 0)
            Row(
              children: [
                Text('${originalPrice.toStringAsFixed(0)} đ', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                const SizedBox(width: 6),
                Text('${discountedPrice.toStringAsFixed(0)} đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Text('${originalPrice.toStringAsFixed(0)} đ', style: const TextStyle(color: Colors.red)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () async {
              if (item.quantity > 1) {
                final newQuantity = item.quantity - 1;
                final userId = CurrentUser().isLogin ? CurrentUser().email! : (await SharedPreferences.getInstance()).getString('cartId') ?? '';
                await CartService.updateCartItemQuantity(userId: userId, variantId: item.variantId, quantity: newQuantity);
                setState(() => item.quantity = newQuantity);
              }
            },
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (item.quantity < variant.stock) {
                final newQuantity = item.quantity + 1;
                final userId = CurrentUser().isLogin ? CurrentUser().email! : (await SharedPreferences.getInstance()).getString('cartId') ?? '';
                await CartService.updateCartItemQuantity(userId: userId, variantId: item.variantId, quantity: newQuantity);
                setState(() => item.quantity = newQuantity);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vượt quá số lượng tồn kho')));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng sản phẩm: $_totalQuantity'),
            const SizedBox(height: 4),
            Text('Tổng tiền hàng: ${formatPrice(_totalPrice + _totalDiscount)}'),
            Text('Tiết kiệm được: -${formatPrice(_totalDiscount)}', style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 4),
            Text('Tổng thanh toán:', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(formatPrice(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            final selectedProducts = _selected.map((id) {
              final variant = _variants.firstWhere((v) => v.id == id);
              final product = _allProducts.firstWhere((p) => p.id == variant.productId);
              final quantity = _cart!.items.firstWhere((i) => i.variantId == id).quantity;
              final discount = product.discountPercent ?? 0;
              return SelectedProduct(variant: variant, quantity: quantity, discount: discount);
            }).toList();
            context.goNamed('cartsummary', extra: {'items': selectedProducts.map((e) => e.toJson()).toList()});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Buy Now', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    ),
  );
}