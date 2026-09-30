import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/checkout_provider.dart';
import '../../orders/models/order_model.dart';

class KitchenOrderCard extends StatelessWidget {
  const KitchenOrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Duration elapsed = DateTime.now().difference(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'طلب ${order.displayId}',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatElapsed(elapsed),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(order.orderType.icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  order.orderType.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (order.isDelivery && order.address != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address!.formatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final CartItemModel item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${item.menuItem.name} ×${item.quantity}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.selectedOptions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        item.selectedOptions
                            .map((option) => option.name)
                            .join(' • '),
                        style: textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                    if (item.notes != null && item.notes!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ملاحظة: ${item.notes}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
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
          ],
        ),
      ),
    );
  }
}
