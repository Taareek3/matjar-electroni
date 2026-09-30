import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../orders/models/order_model.dart';
import '../orders/providers/orders_provider.dart';
import 'widgets/kitchen_order_card.dart';

class KitchenDashboardScreen extends ConsumerStatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  ConsumerState<KitchenDashboardScreen> createState() =>
      _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState
    extends ConsumerState<KitchenDashboardScreen> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<OrderModel> orders = ref.watch(ordersProvider);
    final List<OrderModel> pending = orders
        .where(
          (OrderModel order) =>
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed,
        )
        .toList();
    final List<OrderModel> inKitchen = orders
        .where((OrderModel order) => order.status == OrderStatus.inKitchen)
        .toList();
    final List<OrderModel> ready = orders
        .where(
          (OrderModel order) =>
              order.status == OrderStatus.ready ||
              order.status == OrderStatus.onTheWay,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المطبخ'),
        actions: <Widget>[
          Center(
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${pending.length + inKitchen.length + ready.length} طلب نشط',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KitchenColumn(
                title: 'طلبات جديدة',
                color: AppColors.primary,
                icon: Icons.pending_actions_rounded,
                orders: pending,
                emptyLabel: 'لا توجد طلبات جديدة',
              ),
              const SizedBox(width: 12),
              _KitchenColumn(
                title: 'قيد التحضير',
                color: AppColors.accent,
                icon: Icons.restaurant_rounded,
                orders: inKitchen,
                emptyLabel: 'لا توجد طلبات قيد التحضير',
              ),
              const SizedBox(width: 12),
              _KitchenColumn(
                title: 'جاهزة للتسليم',
                color: AppColors.success,
                icon: Icons.delivery_dining_rounded,
                orders: ready,
                emptyLabel: 'لا توجد طلبات جاهزة',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.color,
    required this.icon,
    required this.orders,
    required this.emptyLabel,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<OrderModel> orders;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.45)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                emptyLabel,
                style: textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            )
          else
            for (final OrderModel order in orders)
              KitchenOrderCard(order: order),
        ],
      ),
    );
  }
}
