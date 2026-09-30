import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/menu_category.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/providers/auth_provider.dart';
import '../../features/cart/models/cart_item_model.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/main_navigation_bar.dart';
import '../../shared/widgets/placeholder_view.dart';
import 'data/menu_repository.dart';
import 'providers/menu_provider.dart';
import 'widgets/category_selector.dart';
import 'widgets/meal_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategoryId = 'all';

  List<MenuItemModel> _filteredItems(MenuData data) {
    if (_selectedCategoryId == 'all') {
      return data.items;
    }
    final bool categoryExists = data.categories
        .any((category) => category.id == _selectedCategoryId);
    if (!categoryExists) {
      return data.items;
    }
    return data.items
        .where(
          (MenuItemModel item) => item.categoryId == _selectedCategoryId,
        )
        .toList();
  }

  void _quickAdd(MenuItemModel meal) {
    if (meal.hasRequiredOptions) {
      context.push('/meal/${meal.id}');
      return;
    }

    ref.read(cartProvider.notifier).addItem(
          CartItemModel(
            menuItem: meal,
            selectedOptions: const [],
            quantity: 1,
          ),
        );

    showAppSnackBar(
      context,
      'تمت الإضافة إلى السلة',
      actionLabel: 'عرض السلة',
      onAction: () => context.go('/cart'),
    );
  }

  void _retry() {
    ref.read(menuProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final int cartCount = ref.watch(
      cartProvider.select((CartState state) => state.totalQuantity),
    );
    final AsyncValue<MenuData> menu = ref.watch(menuProvider);
    final bool isLoggedIn = ref.watch(
      authProvider.select(
        (AsyncValue<AuthState> state) =>
            state.valueOrNull?.isLoggedIn ?? false,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنيو'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
            ),
            tooltip: isLoggedIn ? 'حسابي' : 'تسجيل الدخول',
            onPressed: () =>
                context.go(isLoggedIn ? '/profile' : '/login'),
          ),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'السلة',
                onPressed: () => context.go('/cart'),
              ),
              if (cartCount > 0)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        key: ValueKey<int>(cartCount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: menu.when(
        loading: () => const _MenuLoadingView(),
        error: (Object error, StackTrace stackTrace) => _MenuErrorView(
          onRetry: _retry,
        ),
        data: (MenuData data) => _buildMenuContent(data),
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildMenuContent(MenuData data) {
    final List<MenuItemModel> items = _filteredItems(data);

    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        CategorySelector(
          categories: data.categories,
          selectedId: _selectedCategoryId,
          onSelect: (String id) {
            setState(() => _selectedCategoryId = id);
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? const _MenuEmptyView()
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: GridView(
                    key: ValueKey<String>(_selectedCategoryId),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 256,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    children: items
                        .map(
                          (MenuItemModel meal) => MealCard(
                            meal: meal,
                            categoryIcon:
                                categoryIconById(meal.categoryId),
                            onTap: () => context.push('/meal/${meal.id}'),
                            onQuickAdd: () => _quickAdd(meal),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MenuLoadingView extends StatelessWidget {
  const _MenuLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جارٍ تحميل المنيو...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuErrorView extends StatelessWidget {
  const _MenuErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      icon: Icons.wifi_off_rounded,
      title: 'تعذر تحميل المنيو',
      subtitle: 'تعذّر الاتصال بالخادم — تأكد من تشغيل السيرفر ثم أعد المحاولة',
      action: CustomButton(
        label: 'إعادة المحاولة',
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
      ),
    );
  }
}

class _MenuEmptyView extends StatelessWidget {
  const _MenuEmptyView();

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      icon: Icons.restaurant_menu_rounded,
      title: 'لا توجد وجبات هنا',
      subtitle: 'جرّب تصنيفاً آخر أو أعد تحميل المنيو',
    );
  }
}
