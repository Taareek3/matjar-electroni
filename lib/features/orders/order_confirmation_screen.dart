import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/formatters.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/checkout_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/placeholder_view.dart';
import 'models/order_model.dart';
import 'providers/orders_provider.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OrderModel> matched = ref
        .watch(ordersProvider)
        .where((OrderModel order) => order.id == orderId)
        .toList();
    final OrderModel? order = matched.isEmpty ? null : matched.first;

    if (order == null) {
      Future.microtask(
        () => ref.read(ordersProvider.notifier).ensureOrder(orderId),
      );
      final bool missing = ref
          .read(ordersProvider.notifier)
          .isMissing(orderId);

      if (!missing) {
        return Scaffold(
          appBar: AppBar(title: const Text('تتبع الطلب')),
          body: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ تحميل الطلب...'),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('تتبع الطلب')),
        body: PlaceholderView(
          icon: Icons.receipt_long_rounded,
          title: 'الطلب غير موجود',
          subtitle: 'تعذر العثور على هذا الطلب',
          action: CustomButton(
            label: 'العودة إلى المنيو',
            icon: Icons.restaurant_menu_rounded,
            onPressed: () => context.go('/'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 8),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 750),
                curve: Curves.elasticOut,
                builder:
                    (
                      BuildContext context,
                      double value,
                      Widget? child,
                    ) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: order.cancelled
                        ? const LinearGradient(
                            colors: <Color>[
                              Color(0xFFE53935),
                              Color(0xFFEF5350),
                            ],
                          )
                        : order.status == OrderStatus.delivered
                            ? const LinearGradient(
                                colors: <Color>[
                                  AppColors.success,
                                  Color(0xFF66BB6A),
                                ],
                              )
                            : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: (order.cancelled
                                ? const Color(0xFFE53935)
                                : order.status == OrderStatus.delivered
                                    ? AppColors.success
                                    : AppColors.primary)
                            .withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    order.cancelled ? Icons.close_rounded : Icons.check_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              order.cancelled
                  ? 'تم إلغاء طلبك'
                  : order.status == OrderStatus.pending
                      ? 'تم استلام طلبك بنجاح'
                      : order.status.label(order.orderType),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'رقم الطلب ${order.displayId}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (order.cancelled) ...<Widget>[
              const _CancelledCard(),
              const SizedBox(height: 16),
            ] else ...<Widget>[
              _EstimateCard(order: order),
              const SizedBox(height: 16),
              _StatusCard(order: order),
              const SizedBox(height: 16),
            ],
            _DetailsCard(order: order),
            const SizedBox(height: 16),
            const _PhoneContactCard(),
            const SizedBox(height: 24),
            if (order.canCancel) ...<Widget>[
              OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, ref, order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  'إلغاء الطلب',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
            ],
            CustomButton(
              label: 'العودة إلى المنيو',
              icon: Icons.restaurant_menu_rounded,
              onPressed: () => context.go('/'),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('عرض طلباتي'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('إلغاء الطلب'),
          content: Text(
            'هل تريد إلغاء الطلب ${order.displayId}؟ لن يتم تنفيذه بعد الإلغاء.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('الاحتفاظ بالطلب'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'نعم، إلغاء',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(ordersProvider.notifier).cancelOrder(order.id);
      if (context.mounted) {
        showAppSnackBar(context, 'تم إلغاء الطلب ${order.displayId}');
      }
    } on OrderActionException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message);
      }
    }
  }
}

class _CancelledCard extends StatelessWidget {
  const _CancelledCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFCDD2)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم إلغاء الطلب',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تم إلغاء هذا الطلب بنجاح — يمكنك تصفح المنيو وإنشاء طلب جديد في أي وقت',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    order.isDelivery
                        ? 'الوصول المتوقع'
                        : 'جاهز للاستلام خلال',
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'خلال ~${order.estimatedMinutes} دقيقة',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              order.orderType.icon,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<OrderStatus> flow = order.statusFlow;
    final int activeIndex = flow.indexOf(order.status);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'تتبع الطلب',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.label(order.orderType),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < flow.length; i++)
              _StepTile(
                status: flow[i],
                label: flow[i].label(order.orderType),
                isDone: i < activeIndex,
                isActive: i == activeIndex,
                isLast: i == flow.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.status,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final OrderStatus status;
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bool reached = isDone || isActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDone
                    ? const LinearGradient(
                        colors: <Color>[AppColors.success, Color(0xFF66BB6A)],
                      )
                    : isActive
                        ? AppColors.primaryGradient
                        : null,
                color: reached ? null : const Color(0xFFE0E0E0),
                boxShadow: isActive
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : Icon(
                      status.icon,
                      color: reached ? Colors.white : Colors.white70,
                      size: 20,
                    ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDone ? AppColors.success : const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.primary
                            : isDone
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                ),
                if (isActive) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    'جارٍ التنفيذ...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'تفاصيل الطلب',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: order.orderType.icon,
              label: 'نوع الطلب',
              value: order.orderType.label,
            ),
            const SizedBox(height: 12),
            if (order.isDelivery && order.address != null) ...<Widget>[
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'عنوان التوصيل',
                value: order.address!.formatted,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: order.address!.phone,
              ),
              if (order.address!.driverNotes.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'ملاحظات للسائق',
                  value: order.address!.driverNotes,
                ),
              ],
            ] else ...<Widget>[
              const _DetailRow(
                icon: Icons.storefront_outlined,
                label: 'فرع الاستلام',
                value:
                    '${AppConstants.branchName} — ${AppConstants.branchAddress}',
              ),
            ],
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'وقت الطلب',
              value:
                  '${formatDate(order.createdAt)} — ${formatTime(order.createdAt)}',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: order.paymentMethod.icon,
              label: 'طريقة الدفع',
              value: order.paymentMethod.label,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            for (final CartItemModel item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${item.menuItem.name} ×${item.quantity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    priceText(
                      item.totalPrice,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'الإجمالي النهائي',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: priceText(
                      order.total,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20,
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
    );
  }
}

class _PhoneContactCard extends StatelessWidget {
  const _PhoneContactCard();

  Future<void> _openPhone(BuildContext context) async {
    final Uri uri = Uri.parse('tel:${AppConstants.restaurantPhone}');
    try {
      final bool launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showAppSnackBar(context, 'تعذر فتح تطبيق الاتصال');
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر فتح تطبيق الاتصال');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openPhone(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'التواصل مع المطعم أو الدعم',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اتصل بنا: ${AppConstants.restaurantPhone} — الدعم: ${AppConstants.supportPhone}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.phone_forwarded_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
