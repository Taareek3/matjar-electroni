import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/menu_category.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/option_group_model.dart';
import '../../../core/models/option_model.dart';
import '../../../core/network/api_client.dart';

class MenuData {
  const MenuData({required this.categories, required this.items});

  final List<MenuCategory> categories;
  final List<MenuItemModel> items;

  MenuItemModel? findItemById(String id) {
    for (final MenuItemModel item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}

class MenuRepository {
  MenuRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MenuData> fetchMenu() async {
    final Response<dynamic> response =
        await _apiClient.dio.get<dynamic>('/menu');

    final dynamic body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('استجابة غير صالحة من الخادم');
    }

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('بيانات المنيو مفقودة');
    }

    final dynamic categoriesJson = data['categories'];
    final dynamic itemsJson = data['items'];
    if (categoriesJson is! List<dynamic> || itemsJson is! List<dynamic>) {
      throw const FormatException('شكل بيانات المنيو غير صالح');
    }

    final List<MenuCategory> categories = <MenuCategory>[allCategory];
    categories.addAll(
      categoriesJson.map(
        (dynamic category) =>
            menuCategoryFromJson(category as Map<String, dynamic>),
      ),
    );

    final List<MenuItemModel> items =
        itemsJson.map(_parseItem).toList().cast<MenuItemModel>();

    return MenuData(categories: categories, items: items);
  }

  MenuItemModel _parseItem(dynamic json) {
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    final dynamic groupsJson = map['optionGroups'];

    return MenuItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: (map['imageUrl'] as String?) ?? '',
      categoryId: map['categoryId'] as String,
      optionGroups: groupsJson is List<dynamic>
          ? groupsJson.map(_parseGroup).toList().cast<OptionGroupModel>()
          : const <OptionGroupModel>[],
    );
  }

  OptionGroupModel _parseGroup(dynamic json) {
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    final dynamic optionsJson = map['options'];

    return OptionGroupModel(
      id: map['id'] as String,
      title: map['title'] as String,
      isRequired: map['isRequired'] == true,
      allowMultiple: map['allowMultiple'] == true,
      options: optionsJson is List<dynamic>
          ? optionsJson.map(_parseOption).toList().cast<OptionModel>()
          : const <OptionModel>[],
    );
  }

  OptionModel _parseOption(dynamic json) {
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    return OptionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      additionalPrice: (map['additionalPrice'] as num? ?? 0).toDouble(),
    );
  }
}

final menuRepositoryProvider = Provider<MenuRepository>(
  (Ref ref) => MenuRepository(ref.watch(apiClientProvider)),
);
