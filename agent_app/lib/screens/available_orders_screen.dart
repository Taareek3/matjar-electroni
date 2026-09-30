import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/auth_provider.dart';

class AvailableOrdersScreen extends ConsumerStatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  ConsumerState<AvailableOrdersScreen> createState() =>
      _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends ConsumerState<AvailableOrdersScreen> {
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
      final response = await api.get('/agent/orders/available');
      setState(() {
        _orders = response['data']['orders'] as List<dynamic>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('[AvailableOrders] HTTP ${e.statusCode}: ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[AvailableOrders] ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      setState(() {
        _error = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final api = ref.read(apiProvider);
      await api.post('/agent/orders/$orderId/accept');
      _loadOrders();
    } on ApiException catch (e) {
      debugPrint('[AvailableOrders] قبول HTTP ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[AvailableOrders] قبول: ${error.runtimeType}: $error');
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
        title: const Text('الطلبات المتاحة'),
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
                        'لا توجد طلبات متاحة حالياً',
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
                                      Text(
                                        '${order['totalPrice'].toStringAsFixed(2)}\$',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _acceptOrder(order['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6366F1),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('قبول الطلب'),
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
