import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'product_management_screen.dart';
import 'global_orders_screen.dart';
import 'staff_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    final isAdmin = context.read<AuthProvider>().isAdmin;
    _navItems = [
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', screen: const DashboardScreen()),
      if (isAdmin) _NavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Products', screen: const ProductManagementScreen()),
      _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', screen: const GlobalOrdersScreen()),
      if (isAdmin) _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Staff', screen: const StaffManagementScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _kDark,
      body: Row(
        children: [
          // Side nav for wider screens
          if (MediaQuery.of(context).size.width >= 600)
            _buildSideNav(auth)
          else
            const SizedBox.shrink(),
          Expanded(child: _navItems[_selectedIndex].screen),
        ],
      ),
      // Bottom nav for narrow screens
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _buildBottomNav()
          : null,
    );
  }

  Widget _buildSideNav(AuthProvider auth) {
    return Container(
      width: 220,
      color: _kCard,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: _kOrange.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.store, color: _kOrange, size: 28),
                ),
                const SizedBox(height: 10),
                Text(auth.user?.name ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                Text(auth.isAdmin ? 'Mess Owner' : 'Staff', style: TextStyle(color: _kOrange.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                selected: selected,
                selectedTileColor: _kOrange.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(selected ? item.activeIcon : item.icon, color: selected ? _kOrange : Colors.white54, size: 22),
                title: Text(item.label, style: TextStyle(color: selected ? _kOrange : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 14)),
                onTap: () => setState(() => _selectedIndex = i),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54, size: 22),
            title: const Text('Sign Out', style: TextStyle(color: Colors.white70, fontSize: 14)),
            onTap: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      backgroundColor: const Color(0xFF16213E),
      indicatorColor: const Color(0xFFFF6B35).withOpacity(0.2),
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: _navItems.map((item) => NavigationDestination(
        icon: Icon(item.icon, color: Colors.white54),
        selectedIcon: Icon(item.activeIcon, color: const Color(0xFFFF6B35)),
        label: item.label,
      )).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.screen});
}
