import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_customer_app/core/models/menu_item_model.dart';
import 'package:restaurant_customer_app/core/theme/app_theme.dart';
import 'package:restaurant_customer_app/core/utils/formatters.dart';
import 'package:restaurant_customer_app/features/auth/models/app_user.dart';
import 'package:restaurant_customer_app/features/auth/providers/auth_provider.dart';
import 'package:restaurant_customer_app/features/cart/cart_screen.dart';
import 'package:restaurant_customer_app/features/cart/models/cart_item_model.dart';
import 'package:restaurant_customer_app/features/cart/providers/cart_provider.dart';
import 'package:restaurant_customer_app/features/cart/providers/checkout_provider.dart';
import 'package:restaurant_customer_app/features/checkout/checkout_screen.dart';
import 'package:restaurant_customer_app/features/orders/models/order_model.dart';
import 'package:restaurant_customer_app/features/orders/orders_screen.dart';
import 'package:restaurant_customer_app/features/orders/providers/orders_provider.dart';
import 'package:restaurant_customer_app/shared/widgets/custom_button.dart';

const MenuItemModel expensive = MenuItemModel(
  id: 'i1',
  name: 'وجبة غالية',
  description: 'وصف',
  price: 49.99,
  imageUrl: '',
  categoryId: 'c1',
);

const MenuItemModel cheap = MenuItemModel(
  id: 'i2',
  name: 'وجبة إضافية',
  description: 'وصف',
  price: 26.50,
  imageUrl: '',
  categoryId: 'c1',
);

const MenuItemModel huge = MenuItemModel(
  id: 'i3',
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
  test('setQuantity is idempotent — repeated calls do not compound', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final CartNotifier cart = container.read(cartProvider.notifier);
    cart.addItem(
      CartItemModel(menuItem: cheap, selectedOptions: [], quantity: 1),
    );

    final int target =
        container.read(cartProvider).items.single.quantity + 1;
    cart.setQuantity(0, target);
    cart.setQuantity(0, target);
    cart.setQuantity(0, target);

    expect(container.read(cartProvider).items.single.quantity, 2);
    expect(
      container.read(cartProvider).subtotalPrice,
      closeTo(26.50 * 2, 0.001),
      reason: 'السعر الإجمالي يجب أن يعكس الكمية الفعلية دون تضخيم',
    );
  });

  testWidgets('single tap on + increases quantity by exactly 1',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(child: appShell(const CartScreen())),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(cartProvider.notifier).addItem(
          CartItemModel(menuItem: cheap, selectedOptions: [], quantity: 1),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider).items.single.quantity, 2);
    expect(find.text('2'), findsWidgets);
    expect(
      container.read(cartProvider).subtotalPrice,
      closeTo(53.0, 0.001),
    );
  });

  Future<Widget> buildAt(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(() => _LoggedInAuth()),
        ],
        child: appShell(home),
      ),
    );
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final ProviderContainer container = ProviderScope.containerOf(context);
    container.read(cartProvider.notifier)
      ..addItem(
        CartItemModel(
          menuItem: expensive,
          selectedOptions: [],
          quantity: 3,
        ),
      )
      ..addItem(
        CartItemModel(
          menuItem: cheap,
          selectedOptions: [],
          quantity: 1,
        ),
      );
    final double subtotal = container.read(cartProvider).subtotalPrice;
    container.read(ordersProvider.notifier).debugUpsert(
          OrderModel(
            id: 'price-totals-ui-test',
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
    return home;
  }

  void expectTextsInsideScreen(WidgetTester tester, List<String> texts) {
    final Size screen = tester.getSize(find.byType(MaterialApp));
    for (final String text in texts) {
      final Iterable<Element> matches = tester.elementList(find.text(text));
      expect(matches, isNotEmpty, reason: 'النص "$text" غير موجود');
      for (final Element element in matches) {
        final Rect rect = tester.getRect(
          find.byElementPredicate(
            (Element candidate) => identical(candidate, element),
          ),
        );
        expect(
          rect.left >= -1 &&
              rect.right <= screen.width + 1 &&
              rect.top >= -1 &&
              rect.bottom <= screen.height + 1,
          isTrue,
          reason:
              'النص "$text" خارج الشاشة أو مقتطع: $rect مقابل ${screen.width}x${screen.height}',
        );
      }
    }
  }

  test('order totals above 99 are calculated correctly', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final CartNotifier cart = container.read(cartProvider.notifier);
    cart.addItem(
      CartItemModel(
        menuItem: expensive,
        selectedOptions: [],
        quantity: 3,
      ),
    );
    cart.addItem(
      CartItemModel(menuItem: cheap, selectedOptions: [], quantity: 1),
    );

    final CartState cartState = container.read(cartProvider);
    expect(cartState.subtotalPrice, closeTo(176.47, 0.001));

    final OrderModel order = OrderModel(
      id: 'price-totals-unit-test',
      items: cartState.items,
      orderType: OrderType.delivery,
      paymentMethod: PaymentMethod.cash,
      subtotal: cartState.subtotalPrice,
      deliveryFee: 2.99,
      total: cartState.subtotalPrice + 2.99,
      estimatedMinutes: 40,
      createdAt: DateTime.now(),
    );
    container.read(ordersProvider.notifier).debugUpsert(order);

    expect(order.subtotal, closeTo(176.47, 0.001));
    expect(order.deliveryFee, closeTo(2.99, 0.001));
    expect(order.total, closeTo(179.46, 0.001));
  });

  testWidgets('cart quantity keeps increasing past 99 and totals grow',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(child: appShell(const CartScreen())),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(cartProvider.notifier).addItem(
          CartItemModel(
            menuItem: cheap,
            selectedOptions: [],
            quantity: 1,
          ),
        );
    await tester.pumpAndSettle();

    final Finder addFinder = find.byIcon(Icons.add_rounded);
    expect(addFinder, findsOneWidget);

    for (int quantity = 2; quantity <= 120; quantity++) {
      await tester.tap(addFinder);
      await tester.pump(const Duration(milliseconds: 30));
      if (quantity % 25 == 0 || quantity == 100) {
        expect(
          find.text('$quantity'),
          findsWidgets,
          reason: 'الكمية توقفت عند ${quantity - 1} بدل الوصول إلى $quantity',
        );
      }
    }
    await tester.pumpAndSettle();

    final CartState state = container.read(cartProvider);
    expect(state.items.single.quantity, 120);
    expect(state.subtotalPrice, closeTo(26.50 * 120, 0.001));
    expect(
      find.text('3182.99\$'),
      findsWidgets,
      reason: 'إجمالي السلة (120 × 26.50 + 2.99) يجب أن يظهر صحيحاً',
    );
    expect(find.text('3180.00\$'), findsWidgets);

    for (final Element element in tester.elementList(find.text('120'))) {
      final Rect rect = tester.getRect(
        find.byElementPredicate(
          (Element candidate) => identical(candidate, element),
        ),
      );
      expect(
        rect.height,
        lessThan(30),
        reason: 'رقم الكمية ملتف على سطرين داخل العدّاد: $rect',
      );
    }
    expectTextsInsideScreen(
      tester,
      <String>['120', '3180.00\$', '3182.99\$'],
    );
  });

  testWidgets('checkout shows quantity badge and totals at quantity 120',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(() => _LoggedInAuth()),
        ],
        child: appShell(const CheckoutScreen()),
      ),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(cartProvider.notifier).addItem(
          CartItemModel(
            menuItem: cheap,
            selectedOptions: [],
            quantity: 120,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('120'), findsWidgets);
    expect(find.text(r'3180.00$'), findsWidgets);
    expect(find.text(r'3182.99$'), findsWidgets);
    expectTextsInsideScreen(
      tester,
      <String>['120', '3180.00\$', '3182.99\$', '2.99\$'],
    );
  });

  for (final Size size in <Size>[
    const Size(400, 800),
    const Size(360, 640),
    const Size(320, 568),
  ]) {
    testWidgets('checkout shows correct totals at ${size.width}px',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await buildAt(tester, const CheckoutScreen());

      expect(find.text('176.47\$'), findsWidgets);
      expect(find.text('179.46\$'), findsWidgets);
      expectTextsInsideScreen(
        tester,
        <String>['176.47\$', '179.46\$', '2.99\$'],
      );
    });

    testWidgets('orders list shows correct totals at ${size.width}px',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await buildAt(tester, const OrdersScreen());

      expect(find.text('179.46\$'), findsWidgets);
      expectTextsInsideScreen(tester, <String>['179.46\$']);
    });
  }

  testWidgets('cart screen shows correct totals', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await buildAt(tester, const CartScreen());

    expect(find.text(r'179.46$'), findsWidgets);
    expectTextsInsideScreen(
      tester,
      <String>[r'179.46$', r'149.97$', r'26.50$'],
    );
  });

  test('formatPrice prints hundreds and thousands digits completely', () {
    expect(formatPrice(47.34), '47.34\$');
    expect(formatPrice(147.34), '147.34\$');
    expect(formatPrice(100), '100.00\$');
    expect(formatPrice(1470.5), '1470.50\$');
    expect(formatPrice(12345.67), '12345.67\$');
    expect(
      formatPrice(147.34),
      isNot(anyOf(startsWith('47'), contains('…'))),
      reason: 'القيمة المالية لا يجب أن تفقد خانة المئات أو تُقصّ',
    );
  });

  testWidgets('cart price keeps hundreds digit with no ellipsis cut',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(child: appShell(const CartScreen())),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(cartProvider.notifier).addItem(
          CartItemModel(menuItem: huge, selectedOptions: [], quantity: 1),
        );
    await tester.pumpAndSettle();

    expect(find.text(r'147.34$'), findsWidgets);

    final List<Text> priceTexts =
        tester.widgetList<Text>(find.text(r'147.34$')).toList();
    expect(priceTexts, isNotEmpty);
    for (final Text text in priceTexts) {
      expect(
        text.maxLines,
        isNull,
        reason: 'نص السعر يجب ألا يكون محصوراً في سطر واحد (maxLines)',
      );
      expect(
        text.overflow,
        isNot(TextOverflow.ellipsis),
        reason:
            'نص السعر يجب ألا يستخدم ellipsis لأنه يقتطع خانة المئات في RTL',
      );
    }

    expectTextsInsideScreen(tester, <String>[r'147.34$']);
  });

  testWidgets('button label containing a price is never cut',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      appShell(
        CustomButton(
          label: 'إضافة إلى السلة — 147.34\$',
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(
      find.text('إضافة إلى السلة — 147.34\$'),
    );
    expect(label.maxLines, isNull);
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expectTextsInsideScreen(
      tester,
      <String>['إضافة إلى السلة — 147.34\$'],
    );
  });
}
