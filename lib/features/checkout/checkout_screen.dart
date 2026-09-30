import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/placeholder_view.dart';
import '../auth/models/app_user.dart';
import '../auth/providers/auth_provider.dart';
import '../cart/checkout_actions.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/cart_provider.dart';
import '../cart/providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillAddress());
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _prefillAddress() {
    if (!mounted) return;

    final AppUser? user = ref.read(authProvider).valueOrNull?.user;
    if (user == null) return;

    final CheckoutNotifier notifier = ref.read(checkoutProvider.notifier);
    final CheckoutState checkout = ref.read(checkoutProvider);

    if (checkout.area.trim().isEmpty) {
      final String city = user.city.trim();
      final String line = user.addressLine.trim();
      if (line.isNotEmpty && city.isNotEmpty) {
        notifier.setArea('$city — $line');
      } else if (line.isNotEmpty || city.isNotEmpty) {
        notifier.setArea(line.isNotEmpty ? line : city);
      }
    }
    if (checkout.phone.trim().isEmpty && user.phone.trim().isNotEmpty) {
      notifier.setPhone(user.phone.trim());
    }
  }

  void _onCardNumberChanged(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) {
      digits = digits.substring(0, 16);
    }
    final List<String> groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      final int end = i + 4 > digits.length ? digits.length : i + 4;
      groups.add(digits.substring(i, end));
    }
    final String formatted = groups.join(' ');
    if (value != formatted) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onExpiryChanged(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }
    String formatted = digits;
    if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (value != formatted) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onCvvChanged(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 3) {
      _cvvController.value = TextEditingValue(
        text: digits.substring(0, 3),
        selection: const TextSelection.collapsed(offset: 3),
      );
    }
  }

  String? _validateCardFields(PaymentMethod method) {
    if (!method.requiresCardDetails) return null;

    final String number = _cardNumberController.text.replaceAll(' ', '');
    if (number.length != 16) {
      return 'أدخل رقم بطاقة مكوّن من 16 رقماً';
    }

    final String expiry = _expiryController.text;
    final Match? match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry);
    if (match == null) {
      return 'أدخل تاريخ الانتهاء بصيغة MM/YY';
    }
    final int month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) {
      return 'أدخل تاريخ انتهاء صالحاً';
    }

    if (_cvvController.text.length != 3) {
      return 'أدخل رمز الأمان CVV (3 أرقام)';
    }
    return null;
  }

  Future<void> _pay(PaymentMethod method) async {
    final CartState cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      showAppSnackBar(context, 'السلة فارغة — أضف وجبات أولاً');
      return;
    }

    final String? cardError = _validateCardFields(method);
    if (cardError != null) {
      showAppSnackBar(context, cardError);
      return;
    }

    setState(() => _processing = true);
    await confirmCurrentOrder(context, ref);
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth =
        ref.watch(authProvider).valueOrNull ?? AuthState.empty;
    final CartState cart = ref.watch(cartProvider);
    final CheckoutState checkout = ref.watch(checkoutProvider);
    final CheckoutNotifier notifier = ref.read(checkoutProvider.notifier);
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (!auth.isLoggedIn) {
      return _LoginGate(textTheme: textTheme);
    }

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('صفحة الدفع')),
        body: PlaceholderView(
          icon: Icons.shopping_cart_rounded,
          title: 'لا توجد أصناف للدفع',
          subtitle: 'سلتك فارغة — تصفح المنيو وأضف وجباتك أولاً',
          action: CustomButton(
            label: 'تصفح المنيو',
            icon: Icons.restaurant_menu_rounded,
            onPressed: () => context.go('/'),
          ),
        ),
      );
    }

    final double subtotal = cart.subtotalPrice;
    final double deliveryFee = checkout.deliveryFee;
    final double grandTotal = subtotal + deliveryFee;
    final PaymentMethod method = checkout.paymentMethod;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => context.go('/cart'),
        ),
        title: const Text('صفحة الدفع'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
            children: <Widget>[
              _SectionHeader(
                icon: Icons.restaurant_menu_rounded,
                title: 'طلبك',
                count: cart.totalQuantity,
              ),
              Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < cart.items.length; i++) ...<Widget>[
                        if (i > 0) const Divider(height: 20),
                        _ItemRow(item: cart.items[i]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(
                icon: Icons.receipt_long_rounded,
                title: 'ملخص المبلغ',
              ),
              Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      _PriceRow(label: 'الإجمالي الفرعي', value: subtotal),
                      const SizedBox(height: 12),
                      _PriceRow(
                        label: 'رسوم التوصيل',
                        value: deliveryFee,
                        icon: Icons.delivery_dining_rounded,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'الإجمالي النهائي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: priceText(
                                grandTotal,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(
                icon: Icons.account_balance_wallet_outlined,
                title: 'طريقة الدفع',
              ),
              Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final PaymentMethod option
                          in PaymentMethod.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PaymentOptionTile(
                            method: option,
                            selected: method == option,
                            onTap: () => notifier.setPaymentMethod(option),
                          ),
                        ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: method.requiresCardDetails
                            ? _CardDetailsForm(
                                cardController: _cardNumberController,
                                expiryController: _expiryController,
                                cvvController: _cvvController,
                                onCardChanged: _onCardNumberChanged,
                                onExpiryChanged: _onExpiryChanged,
                                onCvvChanged: _onCvvChanged,
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      if (method == PaymentMethod.applePay ||
                          method == PaymentMethod.stcPay) ...<Widget>[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  method == PaymentMethod.applePay
                                      ? 'سيتم إتمام الدفع عبر Apple Pay عند تأكيد الطلب'
                                      : 'سيتم إتمام الدفع عبر STC Pay عند تأكيد الطلب',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (method == PaymentMethod.cash) ...<Widget>[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'لن تدفع أي مبلغ الآن — المبلغ نقداً عند الاستلام',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
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
                        'الإجمالي مع التوصيل',
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
                          grandTotal,
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
                    label: _processing ? 'جارٍ إتمام الشراء...' : 'إتمام الشراء',
                    icon: Icons.lock_rounded,
                    onPressed: _processing ? null : () => _pay(method),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  const _LoginGate({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => context.go('/cart'),
        ),
        title: const Text('صفحة الدفع'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'سجّل دخولك لإتمام الدفع',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نحتاج بيانات حسابك لإرسال الطلب ومتابعته',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'تسجيل الدخول',
                        icon: Icons.login_rounded,
                        onPressed: () => context.go(
                          '/login',
                          extra: 'checkout',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(
                          '/register',
                          extra: 'checkout',
                        ),
                        child: const Text('إنشاء حساب جديد'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${item.quantity}',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.menuItem.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        priceText(
          item.totalPrice,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final double value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: priceText(
              value,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.07)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Icon(
                  method.icon,
                  size: 22,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      method.label,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      selected ? AppColors.primaryGradient : null,
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFBDBDBD), width: 2),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDetailsForm extends StatelessWidget {
  const _CardDetailsForm({
    required this.cardController,
    required this.expiryController,
    required this.cvvController,
    required this.onCardChanged,
    required this.onExpiryChanged,
    required this.onCvvChanged,
  });

  final TextEditingController cardController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final ValueChanged<String> onCardChanged;
  final ValueChanged<String> onExpiryChanged;
  final ValueChanged<String> onCvvChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'بيانات البطاقة',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardController,
                onChanged: onCardChanged,
                keyboardType: TextInputType.number,
                maxLength: 19,
                style: textTheme.bodyLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0000 0000 0000 0000',
                  labelText: 'رقم البطاقة',
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      onChanged: onExpiryChanged,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'MM/YY',
                        labelText: 'تاريخ الانتهاء',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      onChanged: onCvvChanged,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '123',
                        labelText: 'CVV',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
