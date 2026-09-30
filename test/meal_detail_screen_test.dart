import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_customer_app/core/models/menu_item_model.dart';
import 'package:restaurant_customer_app/core/models/option_group_model.dart';
import 'package:restaurant_customer_app/core/models/option_model.dart';
import 'package:restaurant_customer_app/features/home/data/menu_repository.dart';
import 'package:restaurant_customer_app/features/home/meal_detail_screen.dart';
import 'package:restaurant_customer_app/features/home/providers/menu_provider.dart';
import 'package:restaurant_customer_app/shared/widgets/meal_image.dart';
import 'package:restaurant_customer_app/shared/widgets/quantity_stepper.dart';

class _FakeMenuNotifier extends MenuNotifier {
  _FakeMenuNotifier(this._data);

  final MenuData _data;

  @override
  Future<MenuData> build() async => _data;
}

void main() {
  testWidgets(
    'meal detail shows image, description and scrollable content',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const MenuItemModel item = MenuItemModel(
        id: 'item1',
        name: 'دجاج مشوي',
        description: 'صدور دجاج متبّلة بالأعشاب مع أرز بالسمن وسلطة طازجة',
        price: 32.5,
        imageUrl: 'https://images.unsplash.com/photo-1532550907401',
        categoryId: 'cat1',
        optionGroups: <OptionGroupModel>[
          OptionGroupModel(
            id: 'g1',
            title: 'الإضافات',
            isRequired: false,
            allowMultiple: true,
            options: <OptionModel>[
              OptionModel(id: 'o1', name: 'جبن إضافي', additionalPrice: 3),
              OptionModel(id: 'o2', name: 'صوص إضافي', additionalPrice: 2),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
          menuProvider.overrideWith(
            () => _FakeMenuNotifier(
              const MenuData(
                categories: <Never>[],
                items: <MenuItemModel>[item],
              ),
            ),
          ),
          ],
          child: const MaterialApp(
            home: MealDetailScreen(mealId: 'item1'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('دجاج مشوي'), findsOneWidget);
      expect(
        find.text('صدور دجاج متبّلة بالأعشاب مع أرز بالسمن وسلطة طازجة'),
        findsOneWidget,
      );

      final Size scrollSize = tester.getSize(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollSize.height,
        greaterThan(600),
        reason: 'جسم الصفحة يجب أن يملأ الشاشة وليس صفر',
      );

      final Size imageSize = tester.getSize(find.byType(MealImage).first);
      expect(
        imageSize.width,
        greaterThan(300),
        reason: 'صورة المنتج يجب أن تملأ عرض الشاشة',
      );

      final Size stepperSize = tester.getSize(find.byType(QuantityStepper));
      expect(
        stepperSize.height,
        lessThan(80),
        reason: 'عدّاد الكمية يجب أن يبقى صغيراً ولا يبتلع الشاشة',
      );
    },
  );
}
