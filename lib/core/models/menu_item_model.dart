import 'option_group_model.dart';

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.optionGroups = const <OptionGroupModel>[],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final List<OptionGroupModel> optionGroups;

  bool get hasRequiredOptions =>
      optionGroups.any((OptionGroupModel group) => group.isRequired);
}
