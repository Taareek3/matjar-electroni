import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label, this.route);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      Icons.restaurant_menu_outlined,
      Icons.restaurant_menu,
      'المنيو',
      '/',
    ),
    _NavItem(
      Icons.shopping_cart_outlined,
      Icons.shopping_cart,
      'السلة',
      '/cart',
    ),
    _NavItem(
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      'طلباتي',
      '/orders',
    ),
    _NavItem(Icons.person_outline, Icons.person, 'حسابي', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, _items.length - 1),
      onDestinationSelected: (int index) {
        final String route = _items[index].route;
        if (index != currentIndex) {
          context.go(route);
        }
      },
      destinations: List<NavigationDestination>.from(
        _items.map(
          ( _NavItem item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
        ),
      ),
    );
  }
}
