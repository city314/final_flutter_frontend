import 'package:cpmad_final/pattern/current_user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
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
  final bool isLoggedIn;

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
    this.isLoggedIn = false,
    required this.onSupportTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
  final TextEditingController _searchController = TextEditingController();

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
                controller: _searchController,
                onSubmitted: widget.onSearch,
                decoration: InputDecoration(
                  hintText: 'search',
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: () {
                      final text = _searchController.text.trim();
                      if (text.isNotEmpty) widget.onSearch(text);
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
          if (!isMobile) ...[
            SizedBox(width: isSmallScreen ? 8 : 20),
            TextButton(
              onPressed: widget.onHomeTap,
              child: const Text('HOME', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: widget.onCategoriesTap,
              child: const Text('CATEGORIES', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: widget.onCartTap,
              child: Row(
                children: [
                  const Text('CART', style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 4),
                  Text('${widget.cartItemCount}', style: const TextStyle(color: Colors.black)),
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
                      context.go('');
                      widget.onHomeTap();
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
                      widget.onCategoriesTap();
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
                      widget.onCartTap();
                    },
                  ),
                ),
              ],
              if (CurrentUser().isLogin) ...[
                PopupMenuItem(
                  value: 100,
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Xem profile'),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onProfileTap != null) widget.onProfileTap!();
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
                      if (widget.onLogoutTap != null) widget.onLogoutTap!();
                    },
                  ),
                ),
              ] else ...[
                PopupMenuItem(
                  value: 1,
                  child: ListTile(
                    leading: const Icon(Icons.app_registration),
                    title: const Text('Register'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onRegisterTap();
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Login'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onLoginTap();
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 3,
                  child: ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Support'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSupportTap();
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
