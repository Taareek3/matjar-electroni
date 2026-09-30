import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/option_model.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/checkout_provider.dart';

enum OrderStatus {
  pending,
  confirmed,
  inKitchen,
  ready,
  onTheWay,
  delivered,
  cancelled,
}

OrderStatus orderStatusFromServer(String? raw) {
  switch (raw) {
    case 'CONFIRMED':
      return OrderStatus.confirmed;
    case 'IN_KITCHEN':
      return OrderStatus.inKitchen;
    case 'READY':
      return OrderStatus.ready;
    case 'OUT_FOR_DELIVERY':
      return OrderStatus.onTheWay;
    case 'DELIVERED':
      return OrderStatus.delivered;
    case 'CANCELED':
      return OrderStatus.cancelled;
    case 'PENDING':
    default:
      return OrderStatus.pending;
  }
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.area,
    required this.phone,
    this.building = '',
    this.floor = '',
    this.driverNotes = '',
  });

  final String area;
  final String building;
  final String floor;
  final String phone;
  final String driverNotes;

  String get formatted {
    final List<String> parts = <String>[area];
    if (building.isNotEmpty) {
      parts.add('بناية $building');
    }
    if (floor.isNotEmpty) {
      parts.add('طابق $floor');
    }
    return parts.join('، ');
  }

  String toStored() {
    String value = formatted;
    if (phone.isNotEmpty) {
      value = '$value — هاتف: $phone';
    }
    if (driverNotes.isNotEmpty) {
      value = '$value — ملاحظات: $driverNotes';
    }
    return value;
  }

  factory DeliveryAddress.fromStored(String raw) {
    String rest = raw.trim();
    String driverNotes = '';
    String phone = '';

    const notesTag = '— ملاحظات:';
    final int notesIdx = rest.lastIndexOf(notesTag);
    if (notesIdx >= 0) {
      driverNotes = rest.substring(notesIdx + notesTag.length).trim();
      rest = rest.substring(0, notesIdx).trim();
    }

    const phoneTag = '— هاتف:';
    final int phoneIdx = rest.lastIndexOf(phoneTag);
    if (phoneIdx >= 0) {
      phone = rest.substring(phoneIdx + phoneTag.length).trim();
      rest = rest.substring(0, phoneIdx).trim();
    }

    rest = rest.replaceAll(RegExp(r'\s*—\s*$'), '').trim();

    return DeliveryAddress(area: rest, phone: phone, driverNotes: driverNotes);
  }
}

extension OrderStatusX on OrderStatus {
  String label(OrderType type) {
    switch (this) {
      case OrderStatus.pending:
        return 'تم استلام الطلب';
      case OrderStatus.confirmed:
        return 'تم قبول الطلب';
      case OrderStatus.inKitchen:
        return 'جاري التجهيز في المطبخ';
      case OrderStatus.ready:
        return type == OrderType.delivery
            ? 'الطلب جاهز لدى المطعم'
            : 'جاهز للاستلام';
      case OrderStatus.onTheWay:
        return type == OrderType.delivery
            ? 'الطلب بالطريق إليك'
            : 'جاهز للاستلام';
      case OrderStatus.delivered:
        return type == OrderType.delivery ? 'تم التوصيل' : 'تم الاستلام';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.receipt_long_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.inKitchen:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
        return Icons.inventory_2_rounded;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.items,
    required this.orderType,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.estimatedMinutes,
    required this.createdAt,
    this.orderNumber,
    this.address,
    this.status = OrderStatus.pending,
  });

  final String id;

  /// رقم الطلب المكوّن من 6 أرقام — يولّده الخادم عند إنشاء الطلب.
  final String? orderNumber;
  final List<CartItemModel> items;
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final DeliveryAddress? address;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final int estimatedMinutes;

  bool get cancelled => status == OrderStatus.cancelled;

  bool get isDelivery => orderType == OrderType.delivery;

  bool get canCancel =>
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.inKitchen;

  String get displayId {
    final String? number = orderNumber;
    if (number != null && number.isNotEmpty) {
      return '#$number';
    }
    return '#$id';
  }

  int get totalQuantity => items.fold<int>(
        0,
        (int sum, CartItemModel item) => sum + item.quantity,
      );

  List<OrderStatus> get statusFlow {
    if (orderType == OrderType.delivery) {
      return const <OrderStatus>[
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.inKitchen,
        OrderStatus.ready,
        OrderStatus.onTheWay,
        OrderStatus.delivered,
      ];
    }
    return const <OrderStatus>[
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.inKitchen,
      OrderStatus.ready,
      OrderStatus.delivered,
    ];
  }

  OrderModel copyWith({OrderStatus? status}) {
    return OrderModel(
      id: id,
      items: items,
      orderType: orderType,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      estimatedMinutes: estimatedMinutes,
      createdAt: createdAt,
      orderNumber: orderNumber,
      address: address,
      status: status ?? this.status,
    );
  }

  factory OrderModel.fromServer(Map<String, dynamic> json) {
    final OrderType type = json['orderType'] == 'DELIVERY'
        ? OrderType.delivery
        : OrderType.pickup;

    final List<CartItemModel> items = <CartItemModel>[];
    final dynamic rawItems = json['items'];
    if (rawItems is List) {
      for (final dynamic entry in rawItems) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final Map<String, dynamic> menuItem =
            entry['menuItem'] is Map<String, dynamic>
                ? entry['menuItem'] as Map<String, dynamic>
                : <String, dynamic>{};

        final List<OptionModel> options = <OptionModel>[];
        final dynamic rawOptions = entry['selectedOptions'];
        if (rawOptions is List) {
          for (final dynamic option in rawOptions) {
            if (option is! Map) {
              continue;
            }
            options.add(
              OptionModel(
                id: option['id']?.toString() ?? option['name'].toString(),
                name: option['name']?.toString() ?? '',
                additionalPrice:
                    (option['price'] as num?)?.toDouble() ?? 0,
              ),
            );
          }
        }

        items.add(
          CartItemModel(
            menuItem: MenuItemModel(
              id: menuItem['id']?.toString() ?? '',
              name: menuItem['name']?.toString() ?? 'منتج',
              description: menuItem['description']?.toString() ?? '',
              price: (menuItem['price'] as num?)?.toDouble() ??
                  (entry['price'] as num?)?.toDouble() ??
                  0,
              imageUrl: menuItem['imageUrl']?.toString() ?? '',
              categoryId: menuItem['categoryId']?.toString() ?? '',
            ),
            selectedOptions: options,
            quantity: (entry['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
      }
    }

    final double total = (json['totalPrice'] as num?)?.toDouble() ?? 0;
    final bool isDelivery = type == OrderType.delivery;
    final double itemsTotal = items.fold<double>(
      0,
      (double sum, CartItemModel item) => sum + item.totalPrice,
    );
    double deliveryFee = 0;
    if (isDelivery) {
      deliveryFee = double.parse((total - itemsTotal).toStringAsFixed(2));
      if (deliveryFee.isNaN || deliveryFee < 0) {
        deliveryFee = 0;
      }
    }

    final dynamic rawAddress = json['deliveryAddress'];
    final DeliveryAddress? address = isDelivery &&
            rawAddress is String &&
            rawAddress.trim().isNotEmpty
        ? DeliveryAddress.fromStored(rawAddress)
        : null;

    final dynamic rawPayment = json['paymentMethod'];
    final PaymentMethod paymentMethod = PaymentMethod.values.firstWhere(
      (PaymentMethod method) => method.name == rawPayment,
      orElse: () => PaymentMethod.cash,
    );

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString(),
      items: items,
      orderType: type,
      paymentMethod: paymentMethod,
      subtotal: double.parse((total - deliveryFee).toStringAsFixed(2)),
      deliveryFee: deliveryFee,
      total: total,
      status: orderStatusFromServer(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      estimatedMinutes: isDelivery
          ? AppConstants.deliveryEstimateMinutes
          : AppConstants.pickupEstimateMinutes,
      address: address,
    );
  }
}
