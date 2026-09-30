import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../features/cart/providers/checkout_provider.dart';
import '../../shared/widgets/main_navigation_bar.dart';
import '../../shared/widgets/placeholder_view.dart';
import 'models/order_model.dart';
import 'providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OrderModel> orders = ref.watch(ordersProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: orders.isEmpty
            ? const PlaceholderView(
                icon: Icons.receipt_long_rounded,
                title: 'لا توجد طلبات بعد',
                subtitle: 'ستظهر هنا حالة طلباتك من لحظة التأكيد حتى التوصيل',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(ordersProvider.notifier).refresh(),
                child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final OrderModel order = orders[index];
                  final _StatusVisual visual = _statusVisual(order);

                  return Card(
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/order/${order.id}'),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    visual.color,
                                    visual.color.withOpacity(0.75),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: visual.color.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                visual.icon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'الطلب ${order.displayId}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: visual.color
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              visual.label,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: visual.color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${formatDate(order.createdAt)} • ${formatTime(order.createdAt)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.totalQuantity} أصناف • ${order.paymentMethod.label}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                priceText(
                                  order.total,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.keyboard_arrow_left_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                ),
              ),
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 2),
    );
  }
}

class _StatusVisual {
  const _StatusVisual(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;
}

_StatusVisual _statusVisual(OrderModel order) {
  if (order.cancelled) {
    return const _StatusVisual(
      Color(0xFFE53935),
      Icons.cancel_rounded,
      'ملغي',
    );
  }
  switch (order.status) {
    case OrderStatus.pending:
      return const _StatusVisual(
        Color(0xFFFFA000),
        Icons.receipt_long_rounded,
        'تم الاستلام',
      );
    case OrderStatus.confirmed:
      return const _StatusVisual(
        Color(0xFFFB8C00),
        Icons.check_circle_outline_rounded,
        'تم القبول',
      );
    case OrderStatus.inKitchen:
      return const _StatusVisual(
        Color(0xFFE64A19),
        Icons.restaurant_rounded,
        'جاري التجهيز',
      );
    case OrderStatus.ready:
      return _StatusVisual(
        const Color(0xFF8E24AA),
        Icons.inventory_2_rounded,
        order.isDelivery ? 'جاهز لدى المطعم' : 'جاهز للاستلام',
      );
    case OrderStatus.onTheWay:
      return _StatusVisual(
        const Color(0xFF1E88E5),
        order.isDelivery
            ? Icons.delivery_dining_rounded
            : Icons.storefront_rounded,
        order.isDelivery ? 'بالطريق إليك' : 'جاهز للاستلام',
      );
    case OrderStatus.delivered:
      return _StatusVisual(
        const Color(0xFF43A047),
        Icons.check_circle_rounded,
        order.isDelivery ? 'تم التوصيل' : 'تم الاستلام',
      );
    case OrderStatus.cancelled:
      return const _StatusVisual(
        Color(0xFFE53935),
        Icons.cancel_rounded,
        'ملغي',
      );
  }
}
