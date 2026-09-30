import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/meal_detail_screen.dart';
import '../../features/kitchen/kitchen_dashboard_screen.dart';
import '../../features/orders/order_confirmation_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/placeholder_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) =>
          const RegisterScreen(),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (BuildContext context, GoRouterState state) =>
          const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (BuildContext context, GoRouterState state) =>
          const CheckoutScreen(),
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (BuildContext context, GoRouterState state) =>
          const OrdersScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileScreen(),
    ),
    GoRoute(
      path: '/meal/:id',
      name: 'meal',
      builder: (BuildContext context, GoRouterState state) {
        final String id = state.pathParameters['id'] ?? '';
        return MealDetailScreen(mealId: id);
      },
    ),
    GoRoute(
      path: '/order/:id',
      name: 'order-tracking',
      builder: (BuildContext context, GoRouterState state) {
        final String id = state.pathParameters['id'] ?? '';
        return OrderConfirmationScreen(orderId: id);
      },
    ),
    GoRoute(
      path: '/kitchen',
      name: 'kitchen',
      builder: (BuildContext context, GoRouterState state) =>
          const KitchenDashboardScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      body: PlaceholderView(
        icon: Icons.explore_off_rounded,
        title: 'الصفحة غير موجودة',
        subtitle: 'ربما يكون الرابط قد تغيّر أو حُذفت الصفحة',
        action: CustomButton(
          label: 'العودة إلى المنيو',
          icon: Icons.restaurant_menu_rounded,
          onPressed: () => context.go('/'),
        ),
      ),
    );
  },
);
