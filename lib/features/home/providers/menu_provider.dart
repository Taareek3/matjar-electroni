import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_repository.dart';

class MenuNotifier extends AsyncNotifier<MenuData> {
  @override
  Future<MenuData> build() => ref.read(menuRepositoryProvider).fetchMenu();

  Future<void> refresh() async {
    state = const AsyncValue<MenuData>.loading();
    state = await AsyncValue.guard<MenuData>(
      () => ref.read(menuRepositoryProvider).fetchMenu(),
    );
  }
}

final menuProvider = AsyncNotifierProvider<MenuNotifier, MenuData>(
  MenuNotifier.new,
);
