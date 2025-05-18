import 'package:cpmad_final/screens/user/cart_summary.dart';
import 'package:cpmad_final/screens/user/productdetail.dart';
import 'package:cpmad_final/screens/user/account/user_cart.dart';
import 'package:go_router/go_router.dart';

import '../../screens/user/login.dart';
import '../../screens/user/signup.dart';
import '../../screens/user/home.dart';
import '../../screens/user/otp.dart';
import '../../screens/user/productList.dart';
import '../../screens/user/order_history.dart';
import '../../screens/user/order_detail.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../models/selectedproduct.dart';
import '../screens/admin/admin_brand.dart';
import '../screens/admin/admin_category.dart';
import '../screens/admin/admin_chat.dart';
import '../screens/admin/admin_coupon.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_discount.dart';
import '../screens/admin/admin_order.dart';
import '../screens/admin/admin_product.dart';
import '../screens/admin/admin_product_detail.dart';
import '../screens/admin/admin_support.dart';
import '../screens/admin/admin_user.dart';
import '../screens/admin/admin_wrapper.dart';
import '../screens/admin/component/variant_detail.dart';
import '../screens/user/account/account_screen.dart';
import '../screens/user/account/edit_profile_screen.dart';
import '../screens/user/account/change_password_after_login.dart';
import '../screens/user/change_password.dart';
import '../screens/user/forgot_password.dart';
import '../screens/user/order_done.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/order-history',
      name: 'order-history',
      builder: (context, state) => const OrderHistory(),
    ),
    GoRoute(
      path: '/order-history/order-detail',
      name: 'order-detail',
      builder: (context, state) {
        final orderId = state.extra as String;
        return OrderDetail(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/forgot-password/otp',
      name: 'otp',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final email = data['email'] as String;
        final otp = data['otp'] as String;
        return OtpScreen(email: email, otp: otp);
      },
    ),
    GoRoute(
      path: '/forgot-password/otp/change-password',
      name: 'change_password',
      builder: (context, state) {
        final email = state.extra as String;
        return ChangePasswordScreen(email: email);
      },
    ),
    GoRoute(
      path: '/products',
      name: 'products',
      builder: (context, state) {
        final catId = state.extra as String;
        return ProductList(categoryId: catId);
      },
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => AccountScreen(),
    ),
    GoRoute(
      path: '/account/edit',
      name: 'edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/account/change-password-after-login',
      name: 'change_password_after_login',
      builder: (context, state) => const ChangePasswordAfterLoginScreen(),
    ),
    GoRoute(
      path: '/account/cart',
      name: 'cart',
      builder: (context, state) => UserCartPage(),
    ),
    GoRoute(
      path: '/account/cart/summary',
      name: 'cartsummary',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final List<dynamic> rawItems = extra['items'];
        final List<SelectedProduct> selectedItems = rawItems
            .map((e) => SelectedProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        return CartSummary(selectedItems: selectedItems);
      },
    ),
    GoRoute(
      path: '/order-done',
      name: 'orderDone',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OrderDone(
          discount: extra['discount'],
          finalPrice: extra['finalPrice'],
          orderId: extra['orderId'],
          shippingFee: extra['shippingFee'],
          tax: extra['tax'],
          timeCreate: extra['timeCreate'],
          selectedItems: extra['selectedItems'],
          receiverName: extra['receiverName'],
          phoneNumber: extra['phoneNumber'],
          email: extra['email'],
          address: extra['address'],
          totalPrice: extra['totalPrice'],
          loyaltyUsed: extra['loyaltyUsed'],
          voucherDiscount: extra['voucherDiscount'],
          isVoucherApplied: extra['isVoucherApplied'],
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot_password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/products/:id',
      name: 'product_detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/admin/product-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final Product p = extra['product'];
        final bool isNew = extra['isNew'];

        return AdminProductDetail(
          product: p,
          isNew: isNew,
          onEdit: (_) {},
          onDelete: () {},
        );
      },
    ),
    GoRoute(
      path: '/admin/variant-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final String productId = extra['productId'];
        final Variant? initialVariant = extra['initialVariant'];

        return VariantDetailScreen(
          productId: productId,
          initialVariant: initialVariant,
        );
      },
    ),
    GoRoute(
      path: '/admin/chat',
      name: 'admin_chat',
      builder: (context, state) {
        final email = state.extra as String;
        return CustomerSupportScreen(email: email);
      },
    ),
    ShellRoute(
      // Wrapper duy nhất, quản lý AppBar/Sidebar/BottomNav
      builder: (context, state, child) {
        // chuyển state.location thành selectedIndex
        int _tabIndexFromLoc(String loc) {
          if (loc.startsWith('/admin/dashboard')) return 0;
          if (loc.startsWith('/admin/products'))  return 1;
          if (loc.startsWith('/admin/category'))  return 2;
          if (loc.startsWith('/admin/brand'))     return 3;
          if (loc.startsWith('/admin/users'))     return 4;
          if (loc.startsWith('/admin/orders'))    return 5;
          if (loc.startsWith('/admin/coupons'))   return 6;
          if (loc.startsWith('/admin/discount'))  return 7;
          if (loc.startsWith('/admin/support'))      return 8;
          return 0;
        }

        return AdminHomeWrapper(
          child: child,
          selectedIndex: _tabIndexFromLoc(state.uri.toString()),
          onTabChanged: (i) {
            switch (i) {
              case 0: context.go('/admin/dashboard'); break;
              case 1: context.go('/admin/products');  break;
              case 2: context.go('/admin/category');  break;
              case 3: context.go('/admin/brand');     break;
              case 4: context.go('/admin/users');     break;
              case 5: context.go('/admin/orders');    break;
              case 6: context.go('/admin/coupons');   break;
              case 7: context.go('/admin/discount');  break;
              case 8: context.go('/admin/support');   break;
            }
          },
        );
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin_dashboard',
          builder: (c, s) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          name: 'admin_products',
          builder: (c, s) => AdminProductScreen(),
        ),
        GoRoute(
          path: '/admin/category',
          name: 'admin_category',
          builder: (c, s) => const AdminCategoryScreen(),
        ),
        GoRoute(
          path: '/admin/brand',
          name: 'admin_brand',
          builder: (c, s) => const AdminBrandScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          name: 'admin_orders',
          builder: (c, s) => const AdminOrderScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          name: 'admin_users',
          builder: (c, s) => AdminUserScreen(),
        ),
        GoRoute(
          path: '/admin/coupons',
          name: 'admin_coupons',
          builder: (c, s) => const AdminCouponScreen(),
        ),
        GoRoute(
          path: '/admin/support',
          name: 'admin_support',
          builder: (c, s) => const SupportScreen(),
        ),
        GoRoute(
          path: '/admin/discount',
          name: 'admin_discount',
          builder: (c, s) => const AdminDiscountScreen(),
        ),
      ],
    ),
  ],
);
