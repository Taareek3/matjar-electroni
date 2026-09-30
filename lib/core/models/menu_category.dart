import 'package:flutter/material.dart';

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

const MenuCategory allCategory = MenuCategory(
  id: 'all',
  name: 'الكل',
  icon: Icons.grid_view_rounded,
);

IconData categoryIconById(String categoryId) {
  switch (categoryId) {
    case 'main':
      return Icons.restaurant_rounded;
    case 'pizza':
      return Icons.local_pizza_rounded;
    case 'burger':
      return Icons.lunch_dining_rounded;
    case 'drinks':
      return Icons.local_cafe_rounded;
    case 'desserts':
      return Icons.cake_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

MenuCategory menuCategoryFromJson(Map<String, dynamic> json) {
  final String id = json['id'] as String;
  return MenuCategory(
    id: id,
    name: json['name'] as String,
    icon: categoryIconById(id),
  );
}
