import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/auth_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final response = await api.get('/agent/orders/my');
      setState(() {
        _orders = response['data']['orders'] as List<dynamic>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('[MyOrders] HTTP ${e.statusCode}: ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[MyOrders] ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      setState(() {
        _error = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      final api = ref.read(apiProvider);
      await api.patch('/agent/orders/$orderId/status', body: {
        'status': status,
      });
      _loadOrders();
    } on ApiException catch (e) {
      debugPrint('[MyOrders] تحديث الحالة HTTP ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[MyOrders] تحديث الحالة: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالخادم')),
        );
      }
    }
  }

  Future<void> _sendToDelivery(String orderId) async {
    try {
      final api = ref.read(apiProvider);
      await api.post('/agent/orders/$orderId/send-delivery');
      debugPrint('[MyOrders] تم إرسال الطلب إلى تطبيق الديليفيري: $orderId');
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الطلب إلى تطبيق الديليفيري'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('[MyOrders] إرسال HTTP ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[MyOrders] إرسال: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالخادم')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
                        onPressed: _loadOrders,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد طلبات حالياً',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index] as Map<String, dynamic>;
                          final customer =
                              order['user'] as Map<String, dynamic>;
                          final items = order['items'] as List<dynamic>;
                          final status = order['status'] as String;
                          final sent = order['sentToDelivery'] == true;

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
                                  const SizedBox(height: 8),
                                  Text(
                                    'العميل: ${customer['name']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'الهاتف: ${customer['phone'] ?? 'غير متوفر'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if ((order['deliveryAddress'] ??
                                          customer['addressLine']) !=
                                      null)
                                    Text(
                                      'العنوان: ${order['deliveryAddress'] ?? customer['addressLine']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
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
                                  const SizedBox(height: 12),
                                  if (status == 'CONFIRMED')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(
                                          order['id'],
                                          'IN_KITCHEN',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.restaurant,
                                            size: 18),
                                        label: const Text('بدء التحضير'),
                                      ),
                                    ),
                                  if (status == 'IN_KITCHEN')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(
                                          order['id'],
                                          'READY',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.check_circle,
                                            size: 18),
                                        label: const Text('جاهز للتسليم'),
                                      ),
                                    ),
                                  if (status == 'READY' && !sent)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _sendToDelivery(
                                          order['id'],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6366F1),
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(
                                            Icons.delivery_dining,
                                            size: 18),
                                        label: const Text(
                                            'إرسال إلى تطبيق الديليفيري'),
                                      ),
                                    ),
                                  if (status == 'READY' && sent)
                                    const _InfoBox(
                                      text: 'تم الإرسال إلى عامل التوصيل — بانتظار الاستلام',
                                      color: Colors.indigo,
                                    ),
                                  if (status == 'OUT_FOR_DELIVERY')
                                    const _InfoBox(
                                      text: 'الطلب مع عامل التوصيل الآن',
                                      color: Colors.orange,
                                    ),
                                  if (status == 'DELIVERED')
                                    const _InfoBox(
                                      text: '✓ تم التوصيل بنجاح',
                                      color: Colors.green,
                                    ),
                                  if (status == 'CANCELED')
                                    const _InfoBox(
                                      text: 'تم إلغاء الطلب',
                                      color: Colors.red,
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

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 'PENDING':
        label = 'جديد';
        color = Colors.red;
      case 'CONFIRMED':
        label = 'مؤكد';
        color = Colors.blue;
      case 'IN_KITCHEN':
        label = 'قيد التحضير';
        color = Colors.teal;
      case 'READY':
        label = 'جاهز';
        color = Colors.indigo;
      case 'OUT_FOR_DELIVERY':
        label = 'في الطريق';
        color = Colors.orange;
      case 'DELIVERED':
        label = 'تم التوصيل';
        color = Colors.green;
      case 'CANCELED':
        label = 'ملغي';
        color = Colors.red;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
