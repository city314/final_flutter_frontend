import 'package:flutter/material.dart';
import 'admin_top_navbar.dart';
import 'admin_bottom_navbar.dart';

/// A wrapper widget that provides the common Scaffold layout for the admin section,
/// including AppBar (mobile), Sidebar (web), and BottomNavBar (mobile).
class AdminHomeWrapper extends StatelessWidget {
  /// The main content to display (e.g., Dashboard, Products, etc.)
  final Widget child;

  /// The current navigation index, used to highlight the active tab/item.
  final int selectedIndex;

  /// Callback when the user selects a new tab/item.
  final ValueChanged<int> onTabChanged;

  const AdminHomeWrapper({
    Key? key,
    required this.child,
    required this.selectedIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      // Body: mobile shows the child directly; web shows sidebar + child
      body: isMobile
          ? child
          : Row(
        children: [
          AdminTopNavbar(
            selectedIndex: selectedIndex,
            onItemSelected: onTabChanged,
            userAvatarUrl: 'assets/images/avt_default.png',
            userName: 'Admin',
            userRole: 'Administrator',
          ),
          Expanded(child: child),
        ],
      ),

      // Mobile: show bottom navigation bar; Web: none
      bottomNavigationBar: isMobile
          ? AnimatedBottomNavBar(onItemSelected: onTabChanged)
          : null,
    );
  }
}