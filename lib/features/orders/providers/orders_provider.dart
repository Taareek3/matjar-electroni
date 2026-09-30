import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/checkout_provider.dart';
import '../models/order_model.dart';

class OrderActionException implements Exception {
  OrderActionException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _messageFrom(Object error, String fallback) {
  if (error is DioException) {
    final dynamic data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'تعذر الاتصال بالخادم — تأكد من تشغيل الخادم';
    }
  }
  return fallback;
}

class OrdersNotifier extends Notifier<List<OrderModel>> {
  Timer? _poll;
  final Set<String> _missing = <String>{};

  @override
  List<OrderModel> build() {
    ref.onDispose(() => _poll?.cancel());
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => refresh(),
    );
    ref.listen(authProvider, (_, AsyncValue<AuthState> next) {
      if (next.valueOrNull?.isLoggedIn ?? false) {
        unawaited(refresh());
      }
    });
    unawaited(refresh());
    return const <OrderModel>[];
  }

  bool get _loggedIn =>
      ref.read(authProvider).valueOrNull?.isLoggedIn ?? false;

  Dio get _dio => ref.read(apiClientProvider).dio;

  Future<void> refresh() async {
    if (!_loggedIn) {
      return;
    }
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/orders/my');
      final dynamic data = response.data?['data'];
      final dynamic list = data is Map<String, dynamic> ? data['orders'] : null;
      if (list is! List) {
        return;
      }
      final List<OrderModel> orders = list
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromServer)
          .toList();
      state = orders;
    } on DioException {
      // صامت: جلسة غير صالحة أو خادم غير متاح — تُعاد المحاولة في الدورة القادمة
    } catch (_) {
      // صامت
    }
  }

  OrderModel? orderById(String id) {
    for (final OrderModel order in state) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  bool isMissing(String id) => _missing.contains(id);

  /// إدخال طلب إلى الحالة مباشرة — للاختبارات فقط.
  void debugUpsert(OrderModel order) {
    _upsert(order);
  }

  void _upsert(OrderModel order) {
    state = <OrderModel>[
      order,
      ...state.where((OrderModel existing) => existing.id != order.id),
    ];
  }

  Future<void> ensureOrder(String id) async {
    if (_missing.contains(id) || orderById(id) != null || !_loggedIn) {
      return;
    }
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/orders/$id');
      final dynamic data = response.data?['data'];
      if (data is Map<String, dynamic> && data['order'] is Map) {
        _upsert(
          OrderModel.fromServer(data['order'] as Map<String, dynamic>),
        );
      }
    } on DioException catch (error) {
      if (error.response != null) {
        _missing.add(id);
      }
    } catch (_) {
      // صامت
    }
  }

  Future<OrderModel> placeOrder({
    required List<CartItemModel> items,
    required CheckoutState checkout,
  }) async {
    final bool isDelivery = checkout.isDelivery;
    final DeliveryAddress? address = isDelivery &&
            checkout.area.trim().isNotEmpty
        ? DeliveryAddress(
            area: checkout.area.trim(),
            building: checkout.building.trim(),
            floor: checkout.floor.trim(),
            phone: checkout.phone.trim(),
            driverNotes: checkout.driverNotes.trim(),
          )
        : null;

    final Map<String, dynamic> body = <String, dynamic>{
      'orderType': isDelivery ? 'DELIVERY' : 'TAKEAWAY',
      'paymentMethod': checkout.paymentMethod.name,
      if (address != null) 'deliveryAddress': address.toStored(),
      'items': items
          .map(
            (CartItemModel item) => <String, dynamic>{
              'menuItemId': item.menuItem.id,
              'quantity': item.quantity,
              'selectedOptions': item.selectedOptions
                  .map(
                    (option) => <String, dynamic>{
                      'name': option.name,
                      'price': option.additionalPrice,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>('/orders', data: body);
      final dynamic data = response.data?['data'];
      if (data is! Map<String, dynamic> || data['order'] is! Map) {
        throw OrderActionException('استجابة غير متوقعة من الخادم');
      }
      final OrderModel order =
          OrderModel.fromServer(data['order'] as Map<String, dynamic>);
      _upsert(order);
      return order;
    } on DioException catch (error) {
      throw OrderActionException(_messageFrom(error, 'تعذر إنشاء الطلب'));
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.patch<Map<String, dynamic>>('/orders/$orderId/cancel');
      final dynamic data = response.data?['data'];
      if (data is Map<String, dynamic> && data['order'] is Map) {
        _upsert(
          OrderModel.fromServer(data['order'] as Map<String, dynamic>),
        );
        return;
      }
      await refresh();
    } on DioException catch (error) {
      throw OrderActionException(_messageFrom(error, 'تعذر إلغاء الطلب'));
    }
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<OrderModel>>(
  OrdersNotifier.new,
);
