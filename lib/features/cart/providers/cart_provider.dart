import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';

class CartState {
  const CartState({this.items = const <CartItemModel>[]});

  final List<CartItemModel> items;

  bool get isEmpty => items.isEmpty;

  int get totalQuantity => items.fold<int>(
        0,
        (int sum, CartItemModel item) => sum + item.quantity,
      );

  double get subtotalPrice => items.fold<double>(
        0.0,
        (double sum, CartItemModel item) => sum + item.totalPrice,
      );
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(CartItemModel newItem) {
    final List<CartItemModel> updated = List<CartItemModel>.of(state.items);
    final int index =
        updated.indexWhere((CartItemModel item) => item.isSameConfigurationAs(newItem));

    if (index != -1) {
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + newItem.quantity,
      );
    } else {
      updated.add(newItem);
    }

    state = CartState(items: updated);
  }

  /// تستبدل العنصر بالنسخة ذات الكمية المطلوبة (Immutable — دون تعديل الكائن).
  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    if (quantity < 1) {
      return;
    }
    final List<CartItemModel> updated = List<CartItemModel>.of(state.items);
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = CartState(items: updated);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    final List<CartItemModel> updated = List<CartItemModel>.of(state.items);
    updated.removeAt(index);
    state = CartState(items: updated);
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
