import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import 'cart_provider.dart';

enum OrderType { delivery, pickup }

enum PaymentMethod { cash, mada, applePay, stcPay, creditCard }

extension OrderTypeX on OrderType {
  String get label {
    return this == OrderType.delivery ? 'توصيل للمنزل' : 'استلام من الفرع';
  }

  IconData get icon {
    return this == OrderType.delivery
        ? Icons.delivery_dining_rounded
        : Icons.storefront_rounded;
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'الدفع عند الاستلام';
      case PaymentMethod.mada:
        return 'مدى';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.stcPay:
        return 'STC Pay';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمانية';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.cash:
        return 'ادفع نقداً للموصّل عند وصول الطلب';
      case PaymentMethod.mada:
        return 'بطاقة مدى السعودية — الدفع الآمن';
      case PaymentMethod.applePay:
        return 'ادفع بلمسة واحدة عبر Apple Pay';
      case PaymentMethod.stcPay:
        return 'محفظة STC Pay الإلكترونية';
      case PaymentMethod.creditCard:
        return 'فيزا، ماستركارد';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.mada:
        return Icons.credit_card_rounded;
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.stcPay:
        return Icons.phone_iphone_rounded;
      case PaymentMethod.creditCard:
        return Icons.add_card_rounded;
    }
  }

  bool get requiresCardDetails =>
      this == PaymentMethod.mada || this == PaymentMethod.creditCard;
}

class CheckoutState {
  const CheckoutState({
    this.orderType = OrderType.delivery,
    this.area = '',
    this.building = '',
    this.floor = '',
    this.phone = '',
    this.driverNotes = '',
    this.paymentMethod = PaymentMethod.cash,
  });

  final OrderType orderType;
  final String area;
  final String building;
  final String floor;
  final String phone;
  final String driverNotes;
  final PaymentMethod paymentMethod;

  bool get isDelivery => orderType == OrderType.delivery;

  double get deliveryFee => isDelivery ? AppConstants.deliveryFee : 0.0;

  CheckoutState copyWith({
    OrderType? orderType,
    String? area,
    String? building,
    String? floor,
    String? phone,
    String? driverNotes,
    PaymentMethod? paymentMethod,
  }) {
    return CheckoutState(
      orderType: orderType ?? this.orderType,
      area: area ?? this.area,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      phone: phone ?? this.phone,
      driverNotes: driverNotes ?? this.driverNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void setOrderType(OrderType value) {
    state = state.copyWith(orderType: value);
  }

  void setPaymentMethod(PaymentMethod value) {
    state = state.copyWith(paymentMethod: value);
  }

  void setArea(String value) {
    state = state.copyWith(area: value);
  }

  void setBuilding(String value) {
    state = state.copyWith(building: value);
  }

  void setFloor(String value) {
    state = state.copyWith(floor: value);
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value);
  }

  void setDriverNotes(String value) {
    state = state.copyWith(driverNotes: value);
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);

String? validateCheckout({
  required CartState cart,
  required CheckoutState checkout,
}) {
  if (cart.isEmpty) {
    return 'السلة فارغة — أضف وجبات أولاً';
  }
  return null;
}
