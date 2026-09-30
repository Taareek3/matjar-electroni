import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_customer_app/core/models/menu_item_model.dart';
import 'package:restaurant_customer_app/core/theme/app_theme.dart';
import 'package:restaurant_customer_app/features/auth/models/app_user.dart';
import 'package:restaurant_customer_app/features/auth/providers/auth_provider.dart';
import 'package:restaurant_customer_app/features/cart/cart_screen.dart';
import 'package:restaurant_customer_app/features/cart/models/cart_item_model.dart';
import 'package:restaurant_customer_app/features/cart/providers/cart_provider.dart';
import 'package:restaurant_customer_app/features/cart/providers/checkout_provider.dart';
import 'package:restaurant_customer_app/features/checkout/checkout_screen.dart';
import 'package:restaurant_customer_app/features/home/widgets/meal_card.dart';
import 'package:restaurant_customer_app/features/orders/models/order_model.dart';
import 'package:restaurant_customer_app/features/orders/order_confirmation_screen.dart';
import 'package:restaurant_customer_app/features/orders/orders_screen.dart';
import 'package:restaurant_customer_app/features/orders/providers/orders_provider.dart';

const MenuItemModel salad = MenuItemModel(
  id: 'm1',
  name: 'سلطة كبيرة',
  description: 'وصف',
  price: 73.67,
  imageUrl: '',
  categoryId: 'c1',
);

const MenuItemModel steak = MenuItemModel(
  id: 'm2',
  name: 'ستيك',
  description: 'وصف',
  price: 49.99,
  imageUrl: '',
  categoryId: 'c1',
);

const MenuItemModel huge = MenuItemModel(
  id: 'm3',
  name: 'وجبة بمبلغ كبير',
  description: 'وصف',
  price: 147.34,
  imageUrl: '',
  categoryId: 'c1',
);

class _LoggedInAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    return const AuthState(
      user: AppUser(
        id: 'u1',
        firstName: 'عميل',
        lastName: 'تجريبي',
        name: 'عميل تجريبي',
        email: 'test@mail.com',
        phone: '0500000000',
        country: 'السعودية',
        city: 'الرياض',
        addressLine: 'حي النخيل',
        role: 'CUSTOMER',
      ),
      token: 'token',
    );
  }
}

Widget appShell(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    builder: (BuildContext context, Widget? child) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: home,
  );
}

void main() {
  void expectMoneyFullyPainted(WidgetTester tester, String money) {
    final Finder finder = find.text(money);
    expect(
      tester.any(finder),
      isTrue,
      reason: 'القيمة "$money" غير موجودة في الشاشة أصلاً',
    );
    final Size screen = tester.getSize(find.byType(MaterialApp));
    for (final Element element in tester.elementList(finder)) {
      final RenderParagraph paragraph =
          element.renderObject! as RenderParagraph;
      final TextPainter painter = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.rtl,
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(paragraph.size.width + 1.0),
        reason:
            'القيمة "$money" مقتّعة بصرياً: الطباعة ${painter.width}px داخل صندوق ${paragraph.size.width}px',
      );
      final Rect rect = tester.getRect(
        find.byElementPredicate(
          (Element candidate) => identical(candidate, element),
        ),
      );
      expect(
        rect.left >= -1.0 && rect.right <= screen.width + 1.0,
        isTrue,
        reason: 'القيمة "$money" خارج حدود الشاشة: $rect',
      );
    }
  }

  Future<ProviderContainer> boot(
    WidgetTester tester,
    Size size, {
    required Widget home,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(() => _LoggedInAuth()),
        ],
        child: appShell(home),
      ),
    );
    return ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  void addCartItems(ProviderContainer container) {
    container.read(cartProvider.notifier)
      ..addItem(
        CartItemModel(menuItem: salad, selectedOptions: [], quantity: 2),
      )
      ..addItem(
        CartItemModel(menuItem: steak, selectedOptions: [], quantity: 3),
      );
  }

  Future<void> scrollUntilVisibleInView(
    WidgetTester tester,
    Finder finder,
  ) async {
    final Size screen = tester.getSize(find.byType(MaterialApp));
    for (int i = 0; i < 60; i++) {
      if (tester.any(finder)) {
        final Rect rect = tester.getRect(finder.first);
        if (rect.top >= 0 && rect.bottom <= screen.height) {
          return;
        }
      }
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
    }
    fail('تعذر الوصول إلى $finder بعد التمرير');
  }

  for (final int width in <int>[280, 300, 320, 360, 375, 400, 430]) {
    final Size size = Size(width.toDouble(), 740);

    testWidgets('cart: all money fully painted at ${width}px',
        (WidgetTester tester) async {
      final ProviderContainer container =
          await boot(tester, size, home: const CartScreen());
      addCartItems(container);
      await tester.pumpAndSettle();

      expectMoneyFullyPainted(tester, '147.34\$');
      expectMoneyFullyPainted(tester, '149.97\$');
      expectMoneyFullyPainted(tester, '300.30\$');
    });

    testWidgets('checkout: all money fully painted at ${width}px',
        (WidgetTester tester) async {
      final ProviderContainer container =
          await boot(tester, size, home: const CheckoutScreen());
      addCartItems(container);
      await tester.pumpAndSettle();

      expectMoneyFullyPainted(tester, '147.34\$');
      expectMoneyFullyPainted(tester, '149.97\$');
      expectMoneyFullyPainted(tester, '297.31\$');
      expectMoneyFullyPainted(tester, '300.30\$');
      expectMoneyFullyPainted(tester, '2.99\$');
    });

    testWidgets('orders list: total fully painted at ${width}px',
        (WidgetTester tester) async {
      final ProviderContainer container =
          await boot(tester, size, home: const OrdersScreen());
      addCartItems(container);
      final double subtotal =
          container.read(cartProvider).subtotalPrice;
      container.read(ordersProvider.notifier).debugUpsert(
            OrderModel(
              id: 'orders-list-test',
              items: container.read(cartProvider).items,
              orderType: OrderType.delivery,
              paymentMethod: PaymentMethod.cash,
              subtotal: subtotal,
              deliveryFee: 2.99,
              total: subtotal + 2.99,
              estimatedMinutes: 40,
              createdAt: DateTime.now(),
            ),
          );
      await tester.pumpAndSettle();

      expectMoneyFullyPainted(tester, '300.30\$');
    });

    testWidgets('order confirmation: all money fully painted at ${width}px',
        (WidgetTester tester) async {
      final ProviderContainer container =
          await boot(tester, size, home: const SizedBox.shrink());
      addCartItems(container);
      final double subtotal =
          container.read(cartProvider).subtotalPrice;
      final OrderModel order = OrderModel(
        id: 'order-confirmation-test',
        items: container.read(cartProvider).items,
        orderType: OrderType.delivery,
        paymentMethod: PaymentMethod.cash,
        subtotal: subtotal,
        deliveryFee: 2.99,
        total: subtotal + 2.99,
        estimatedMinutes: 40,
        createdAt: DateTime.now(),
      );
      container.read(ordersProvider.notifier).debugUpsert(order);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authProvider.overrideWith(() => _LoggedInAuth()),
          ],
          child: appShell(OrderConfirmationScreen(orderId: order.id)),
        ),
      );
      await tester.pumpAndSettle();

      await scrollUntilVisibleInView(tester, find.text('147.34\$'));
      await scrollUntilVisibleInView(tester, find.text('149.97\$'));
      await scrollUntilVisibleInView(tester, find.text('300.30\$'));

      expectMoneyFullyPainted(tester, '147.34\$');
      expectMoneyFullyPainted(tester, '149.97\$');
      expectMoneyFullyPainted(tester, '300.30\$');
    });
  }

  testWidgets('meal card: big price fully painted inside narrow card',
      (WidgetTester tester) async {
    await boot(
      tester,
      const Size(375, 740),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 150,
            child: MealCard(
              meal: huge,
              categoryIcon: Icons.restaurant_rounded,
              onTap: () {},
              onQuickAdd: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectMoneyFullyPainted(tester, '147.34\$');
  });
}
