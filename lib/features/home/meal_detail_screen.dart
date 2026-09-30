import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/menu_category.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/models/option_group_model.dart';
import '../../core/models/option_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../features/cart/models/cart_item_model.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/meal_image.dart';
import '../../shared/widgets/placeholder_view.dart';
import '../../shared/widgets/quantity_stepper.dart';
import 'data/menu_repository.dart';
import 'providers/menu_provider.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.mealId});

  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MenuData> menu = ref.watch(menuProvider);

    return menu.when(
      loading: () => const _MealDetailLoadingView(),
      error: (Object error, StackTrace stackTrace) => _MealDetailErrorView(
        onRetry: () => ref.read(menuProvider.notifier).refresh(),
      ),
      data: (MenuData data) {
        final MenuItemModel? meal = data.findItemById(mealId);
        if (meal == null) {
          return const MealNotFoundScreen();
        }
        return _MealDetailContent(menuItem: meal);
      },
    );
  }
}

class _MealDetailContent extends ConsumerStatefulWidget {
  const _MealDetailContent({required this.menuItem});

  final MenuItemModel menuItem;

  @override
  ConsumerState<_MealDetailContent> createState() =>
      _MealDetailContentState();
}

class _MealDetailContentState extends ConsumerState<_MealDetailContent> {
  final TextEditingController _notesController = TextEditingController();
  final Map<String, List<String>> _selectedOptionIds =
      <String, List<String>>{};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    for (final OptionGroupModel group in widget.menuItem.optionGroups) {
      if (!group.allowMultiple && group.options.isNotEmpty) {
        _selectedOptionIds[group.id] = <String>[group.options.first.id];
      } else {
        _selectedOptionIds[group.id] = <String>[];
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    double extras = 0;
    for (final OptionGroupModel group in widget.menuItem.optionGroups) {
      final List<String> selected = _selectedOptionIds[group.id] ?? <String>[];
      for (final OptionModel option in group.options) {
        if (selected.contains(option.id)) {
          extras += option.additionalPrice;
        }
      }
    }
    return widget.menuItem.price + extras;
  }

  double get _totalPrice => _unitPrice * _quantity;

  List<OptionModel> get _selectedOptions {
    final List<OptionModel> result = <OptionModel>[];
    for (final OptionGroupModel group in widget.menuItem.optionGroups) {
      final List<String> selected = _selectedOptionIds[group.id] ?? <String>[];
      for (final OptionModel option in group.options) {
        if (selected.contains(option.id)) {
          result.add(option);
        }
      }
    }
    return result;
  }

  void _toggleMultiple(OptionGroupModel group, OptionModel option, bool? checked) {
    setState(() {
      final List<String> current =
          List<String>.of(_selectedOptionIds[group.id] ?? <String>[]);
      if (checked == true) {
        current.add(option.id);
      } else {
        current.remove(option.id);
      }
      _selectedOptionIds[group.id] = current;
    });
  }

  void _selectSingle(OptionGroupModel group, OptionModel option) {
    setState(() {
      _selectedOptionIds[group.id] = <String>[option.id];
    });
  }

  void _addToCart() {
    for (final OptionGroupModel group in widget.menuItem.optionGroups) {
      final List<String> selected = _selectedOptionIds[group.id] ?? <String>[];
      if (group.isRequired && selected.isEmpty) {
        showAppSnackBar(context, 'يرجى اختيار ${group.title}');
        return;
      }
    }

    final String notes = _notesController.text.trim();

    ref.read(cartProvider.notifier).addItem(
          CartItemModel(
            menuItem: widget.menuItem,
            selectedOptions: _selectedOptions,
            quantity: _quantity,
            notes: notes.isEmpty ? null : notes,
          ),
        );

    showAppSnackBar(
      context,
      'تمت الإضافة إلى السلة',
      actionLabel: 'عرض السلة',
      onAction: () => context.go('/cart'),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final MenuItemModel meal = widget.menuItem;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Hero(
                    tag: 'meal-image-${meal.id}',
                    child: MealImage(
                      url: meal.imageUrl,
                      icon: categoryIconById(meal.categoryId),
                      height: 300,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                        stops: const <double>[0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: MediaQuery.of(context).padding.top + 8,
                  start: 16,
                  child: Material(
                    color: Colors.black38,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          meal.name,
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: priceText(
                          meal.price,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final OptionGroupModel group in meal.optionGroups)
                    _buildOptionGroupCard(context, group),
                  if (meal.optionGroups.isNotEmpty) const SizedBox(height: 8),
                  _buildNotesSection(context),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildOptionGroupCard(BuildContext context, OptionGroupModel group) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(group.title, style: textTheme.titleLarge),
                ),
                if (group.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مطلوب',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final OptionModel option in group.options)
              group.allowMultiple
                  ? _buildCheckboxTile(context, group, option)
                  : _buildRadioTile(context, group, option),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(
    BuildContext context,
    OptionGroupModel group,
    OptionModel option,
  ) {
    final List<String> selected = _selectedOptionIds[group.id] ?? <String>[];

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      title: Text(
        option.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      secondary: _buildOptionPrice(option),
      value: selected.contains(option.id),
      onChanged: (bool? checked) => _toggleMultiple(group, option, checked),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    OptionGroupModel group,
    OptionModel option,
  ) {
    final List<String> selected = _selectedOptionIds[group.id] ?? <String>[];

    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      title: Text(
        option.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      secondary: _buildOptionPrice(option),
      value: option.id,
      groupValue: selected.isEmpty ? null : selected.first,
      onChanged: (String? selectedId) {
        if (selectedId != null) {
          _selectSingle(group, option);
        }
      },
    );
  }

  Widget? _buildOptionPrice(OptionModel option) {
    if (option.additionalPrice <= 0) {
      return null;
    }
    return Text(
      '+',
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ملاحظات مخصصة للمطبخ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          minLines: 2,
          decoration: const InputDecoration(
            hintText: 'مثال: بدون بصل، صوص خارجي، ناضج جيداً...',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final int currentQuantity = _quantity;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: <Widget>[
            QuantityStepper(
              quantity: currentQuantity,
              onIncrement: () {
                if (currentQuantity < 20) {
                  setState(() => _quantity = currentQuantity + 1);
                }
              },
              onDecrement: () {
                if (currentQuantity > 1) {
                  setState(() => _quantity = currentQuantity - 1);
                }
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: 'إضافة إلى السلة — ${formatPrice(_totalPrice)}',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: _addToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealDetailLoadingView extends StatelessWidget {
  const _MealDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الوجبة')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
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
                'جارٍ تحميل الوجبة...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealDetailErrorView extends StatelessWidget {
  const _MealDetailErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الوجبة')),
      body: PlaceholderView(
        icon: Icons.wifi_off_rounded,
        title: 'تعذر تحميل الوجبة',
        subtitle:
            'تعذّر الاتصال بالخادم — تأكد من تشغيل السيرفر ثم أعد المحاولة',
        action: CustomButton(
          label: 'إعادة المحاولة',
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

class MealNotFoundScreen extends StatelessWidget {
  const MealNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وجبة غير موجودة')),
      body: PlaceholderView(
        icon: Icons.error_outline_rounded,
        title: 'وجبة غير موجودة',
        subtitle: 'ربما تم حذفها من المنيو أو تغيّر الرابط',
        action: CustomButton(
          label: 'العودة إلى المنيو',
          icon: Icons.restaurant_menu_rounded,
          onPressed: () => context.go('/'),
        ),
      ),
    );
  }
}
