import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'staff_qr_scanner_screen.dart';
import 'staff_orders_screen.dart';
import 'staff_plates_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _selectedIndex = 0;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Scan QR'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.set_meal_outlined, activeIcon: Icons.set_meal, label: 'Plates'),
  ];

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0: return const StaffQrScannerScreen();
      case 1: return const StaffOrdersScreen();
      case 2: return const StaffPlatesScreen();
      default: return const StaffQrScannerScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _kDark,
      body: Column(
        children: [
          // Header
          Container(
            color: _kCard,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _kOrange.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: _kOrange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.user?.name ?? 'Staff', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          const Text('Mess Staff', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white54, size: 22),
                      onPressed: () async => await context.read<AuthProvider>().logout(),
                      tooltip: 'Sign Out',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _currentScreen),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _kCard,
        indicatorColor: _kOrange.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.icon, color: Colors.white54),
          selectedIcon: Icon(item.activeIcon, color: _kOrange),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
