import 'package:flutter/material.dart';

typedef NavItemCallback = void Function(int index);

class AdminTopNavbar extends StatelessWidget {
  final int selectedIndex;
  final NavItemCallback onItemSelected;
  final String userAvatarUrl;
  final String userName;
  final String userRole;

  const AdminTopNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userAvatarUrl,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
      _NavItem(icon: Icons.inventory_2_outlined, label: 'Product Management'),
      _NavItem(icon: Icons.category, label: 'Category Management'),
      _NavItem(icon: Icons.business, label: 'Brand Management'),
      _NavItem(icon: Icons.people_outline, label: 'User Management'),
      _NavItem(icon: Icons.receipt_long, label: 'Order Management'),
      _NavItem(icon: Icons.local_offer_outlined, label: 'Coupon Management'),
      _NavItem(icon: Icons.percent, label: 'Discount Management'),
      _NavItem(icon: Icons.chat_bubble_outline, label: 'Customer Support'),
    ];

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo / App name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Menu items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final itm = items[i];
                final selected = i == selectedIndex;
                return ListTile(
                  leading: Icon(itm.icon,
                      color: selected ? Colors.white : Colors.black54),
                  title: Text(
                    itm.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: Colors.blueAccent.shade700,
                  onTap: () => onItemSelected(i),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  dense: true,
                );
              },
            ),
          ),

          const Divider(height: 1),
          // Profile & Logout
          ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(userAvatarUrl),
            ),
            title: Text(userName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(userRole, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon:
              const Icon(Icons.power_settings_new, color: Colors.redAccent),
              onPressed: () {
                // TODO: xử lý logout
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
