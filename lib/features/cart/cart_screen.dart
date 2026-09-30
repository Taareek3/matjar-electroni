import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/menu_category.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/main_navigation_bar.dart';
import '../../shared/widgets/placeholder_view.dart';
import 'models/cart_item_model.dart';
import 'providers/cart_provider.dart';
import 'providers/checkout_provider.dart';
import 'widgets/cart_item_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void _confirmOrder(BuildContext context, WidgetRef ref) {
    final AuthState auth =
        ref.read(authProvider).valueOrNull ?? AuthState.empty;

    if (!auth.isLoggedIn) {
      showAppSnackBar(context, 'سجّل دخولك لإتمام الدفع');
      context.go('/login', extra: 'checkout');
      return;
    }

    context.go('/checkout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartState cart = ref.watch(cartProvider);
    final CheckoutState checkout = ref.watch(checkoutProvider);
    final double grandTotal = cart.subtotalPrice + checkout.deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
        actions: <Widget>[
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'إفراغ السلة',
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                showAppSnackBar(context, 'تم إفراغ السلة');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isEmpty
          ? PlaceholderView(
              icon: Icons.shopping_cart_rounded,
              title: 'سلتك فارغة',
              subtitle: 'أضف أطباقك المفضلة من المنيو لتظهر هنا',
              action: CustomButton(
                label: 'تصفح المنيو',
                icon: Icons.restaurant_menu_rounded,
                onPressed: () => context.go('/'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                _SectionTitle(
                  icon: Icons.restaurant_rounded,
                  title: 'المنيو المطلوب',
                  count: cart.totalQuantity,
                ),
                for (final MapEntry<int, CartItemModel> entry
                    in cart.items.asMap().entries)
                  CartItemCard(
                    item: entry.value,
                    categoryIcon:
                        categoryIconById(entry.value.menuItem.categoryId),
                    onIncrement: () => ref
                        .read(cartProvider.notifier)
                        .setQuantity(entry.key, entry.value.quantity + 1),
                    onDecrement: () => ref
                        .read(cartProvider.notifier)
                        .setQuantity(entry.key, entry.value.quantity - 1),
                    onRemove: () {
                      ref.read(cartProvider.notifier).removeItem(entry.key);
                      showAppSnackBar(context, 'تم حذف الوجبة من السلة');
                    },
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!cart.isEmpty)
              _CheckoutBar(
                total: grandTotal,
                onConfirm: () => _confirmOrder(context, ref),
              ),
            const MainNavigationBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.onConfirm,
  });

  final double total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surfaceLight,
      elevation: 16,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'الإجمالي',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: priceText(
                      total,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: 'تأكيد وإرسال الطلب',
                icon: Icons.check_circle_rounded,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
