import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/auth_provider.dart';

class MyDeliveriesScreen extends ConsumerStatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  ConsumerState<MyDeliveriesScreen> createState() =>
      _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends ConsumerState<MyDeliveriesScreen> {
  List<dynamic> _deliveries = [];
  bool _isLoading = true;
  String? _error;
  String? _completingId;
  final Map<String, TextEditingController> _orderNumberControllers = {};

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  TextEditingController _controllerFor(String orderId) {
    return _orderNumberControllers.putIfAbsent(
      orderId,
      () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _orderNumberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final response = await api.get('/delivery/orders/my');
      setState(() {
        _deliveries = response['data']['orders'] as List<dynamic>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('[MyDeliveries] HTTP ${e.statusCode}: ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[MyDeliveries] ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      setState(() {
        _error = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOrder(String orderId) async {
    final dynamic match = _deliveries.firstWhere(
      (dynamic o) => o['id'] == orderId,
      orElse: () => null,
    );
    final String expected =
        (match is Map ? (match['orderNumber'] ?? '') : '').toString().trim();
    final String entered = _controllerFor(orderId).text.trim();

    if (entered.length != 6 || entered != expected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في الطلب'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _completingId = orderId);
    try {
      final api = ref.read(apiProvider);
      await api.patch(
        '/delivery/orders/$orderId/status',
        body: {'status': 'DELIVERED', 'orderNumber': entered},
      );
      debugPrint('[MyDeliveries] تم التسليم: $orderId');
      _controllerFor(orderId).clear();
      await _loadDeliveries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم توصيل الطلب'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('[MyDeliveries] تسليم HTTP ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[MyDeliveries] تسليم: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر الاتصال بالخادم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسليماتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeliveries,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _deliveries.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد تسليمات حالياً',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDeliveries,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _deliveries.length,
                        itemBuilder: (context, index) {
                          final order =
                              _deliveries[index] as Map<String, dynamic>;
                          final customer =
                              order['user'] as Map<String, dynamic>;
                          final items = order['items'] as List<dynamic>;
                          final status = order['status'] as String;
                          final isOut = status == 'OUT_FOR_DELIVERY';
                          final completing = _completingId == order['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'طلب #${order['id'].toString().substring(0, 8)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _StatusChip(status: status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'المستلم: ${customer['name'] ?? 'عميل'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if ((order['deliveryAddress'] ??
                                          customer['addressLine']) !=
                                      null)
                                    Text(
                                      '📍 ${order['deliveryAddress'] ?? customer['addressLine']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if (customer['phone'] != null)
                                    Text(
                                      '📞 ${customer['phone']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  const Divider(height: 20),
                                  ...items.map((item) {
                                    final menuItem =
                                        item['menuItem'] as Map<String, dynamic>;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${item['quantity']}x ${menuItem['name']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'الإجمالي',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${order['totalPrice'].toStringAsFixed(2)}\$',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (isOut) ...[
                                    TextField(
                                      controller: _controllerFor(order['id']
                                          .toString()),
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        labelText: 'أدخل رقم الطلب',
                                        hintText: '······',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.pin_rounded,
                                          color: Color(0xFF059669),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF059669),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: completing
                                            ? null
                                            : () =>
                                                _completeOrder(order['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF059669),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        icon: completing
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.check,
                                                size: 18),
                                        label: const Text(
                                          'تم توصيل الطلب',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              Colors.green.shade200,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green,
                                              size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'تم تسليم الطلب',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'OUT_FOR_DELIVERY' => ('في الطريق', const Color(0xFFF59E0B)),
      'DELIVERED' => ('تم التوصيل', Colors.green),
      _ => (status, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
