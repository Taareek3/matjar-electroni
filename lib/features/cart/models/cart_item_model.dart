import '../../../core/models/menu_item_model.dart';
import '../../../core/models/option_model.dart';

class CartItemModel {
  CartItemModel({
    required this.menuItem,
    required this.selectedOptions,
    required this.quantity,
    this.notes,
  })  : basePrice = menuItem.price,
        optionsPrice = selectedOptions.fold<double>(
          0.0,
          (double sum, OptionModel option) => sum + option.additionalPrice,
        );

  final MenuItemModel menuItem;
  final List<OptionModel> selectedOptions;
  final int quantity;
  final String? notes;

  /// السعر الأساسي للوجبة — قيمة ثابتة لا تتغير داخل الكائن.
  final double basePrice;

  /// سعر الإضافات المختارة — قيمة ثابتة لا تتغير داخل الكائن.
  final double optionsPrice;

  /// سعر القطعة الواحدة = السعر الأساسي + سعر الإضافات (يُحسب ديناميكياً).
  double get unitPrice => basePrice + optionsPrice;

  /// سعر المجموعة = سعر القطعة × الكمية (يُحسب ديناميكياً).
  double get totalPrice => unitPrice * quantity;

  /// نسخة جديدة تغيّر الكمية فقط دون المساس بالأسعار الأساسية.
  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      menuItem: menuItem,
      selectedOptions: selectedOptions,
      quantity: quantity ?? this.quantity,
      notes: notes,
    );
  }

  bool isSameConfigurationAs(CartItemModel other) {
    if (other.menuItem.id != menuItem.id) {
      return false;
    }
    if ((other.notes ?? '') != (notes ?? '')) {
      return false;
    }
    final Set<String> thisIds =
        selectedOptions.map((OptionModel option) => option.id).toSet();
    final Set<String> otherIds =
        other.selectedOptions.map((OptionModel option) => option.id).toSet();
    return thisIds.length == otherIds.length && thisIds.containsAll(otherIds);
  }
}
