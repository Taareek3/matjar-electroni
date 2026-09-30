import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/auth_provider.dart';

class ReadyOrdersScreen extends ConsumerStatefulWidget {
  const ReadyOrdersScreen({super.key});

  @override
  ConsumerState<ReadyOrdersScreen> createState() =>
      _ReadyOrdersScreenState();
}

class _ReadyOrdersScreenState extends ConsumerState<ReadyOrdersScreen> {
  List<dynamic> _orders = [];
  Map<String, dynamic> _origin = {};
  bool _isLoading = true;
  String? _error;
  String? _acceptingId;

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
      final response = await api.get('/delivery/orders/ready');
      setState(() {
        _orders = response['data']['orders'] as List<dynamic>;
        _origin = (response['data']['origin'] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('[ReadyOrders] HTTP ${e.statusCode}: ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[ReadyOrders] ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      setState(() {
        _error = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    setState(() => _acceptingId = orderId);
    try {
      final api = ref.read(apiProvider);
      await api.post('/delivery/orders/$orderId/accept');
      debugPrint('[ReadyOrders] تم استلام الطلب: $orderId');
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استلام الطلب — بانظر إلى تبويب تسليماتي'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('[ReadyOrders] استلام HTTP ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[ReadyOrders] استلام: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالخادم')),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات جاهزة'),
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
                        'لا توجد طلبات جاهزة حالياً',
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
                          final accepting = _acceptingId == order['id'];

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
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _RouteRow(
                                    icon: Icons.store,
                                    color: const Color(0xFF059669),
                                    label: 'من (الاستلام)',
                                    title: _origin['name']?.toString() ??
                                        'المطعم',
                                    subtitle:
                                        _origin['address']?.toString() ?? '',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  _RouteRow(
                                    icon: Icons.person_pin_circle,
                                    color: const Color(0xFFF59E0B),
                                    label: 'إلى (التسليم)',
                                    title:
                                        customer['name']?.toString() ?? 'عميل',
                                    subtitle: [
                                      (order['deliveryAddress'] ??
                                              customer['addressLine'])
                                          ?.toString(),
                                      customer['phone'] != null
                                          ? '📞 ${customer['phone']}'
                                          : null,
                                    ].whereType<String>().join(' · '),
                                  ),
                                  const Divider(height: 24),
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
                                    child: ElevatedButton.icon(
                                      onPressed: accepting
                                          ? null
                                          : () => _acceptOrder(order['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: accepting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.check, size: 18),
                                      label: const Text('استلام الطلب'),
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

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
