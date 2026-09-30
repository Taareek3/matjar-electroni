import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_snackbar.dart';
import '../orders/models/order_model.dart';
import '../orders/providers/orders_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/checkout_provider.dart';

Future<void> confirmCurrentOrder(
  BuildContext context,
  WidgetRef ref,
) async {
  final CartState cart = ref.read(cartProvider);
  final CheckoutState checkout = ref.read(checkoutProvider);

  final String? error = validateCheckout(cart: cart, checkout: checkout);
  if (error != null) {
    showAppSnackBar(context, error);
    return;
  }

  try {
    final OrderModel order = await ref
        .read(ordersProvider.notifier)
        .placeOrder(items: cart.items, checkout: checkout);

    ref.read(cartProvider.notifier).clear();

    if (!context.mounted) return;
    showAppSnackBar(context, 'تم استلام طلبك بنجاح');
    context.go('/order/${order.id}');
  } on OrderActionException catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(context, e.message);
  }
}
