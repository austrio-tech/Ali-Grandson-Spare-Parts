import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'admin_order_detail_page.dart';

class ManageOrdersPage extends StatefulWidget {
  final String? filter;
  const ManageOrdersPage({super.key, this.filter});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    final orders = await DatabaseHelper.instance.getAllOrders(filter: widget.filter);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Manage Orders';
    if (widget.filter == 'pending') title = 'Pending Orders';
    if (widget.filter == 'completed') title = 'Completed Orders';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Order #${order['id']} - ${order['user_username']}'),
                        subtitle: Text('Total: OMR ${order['total_price']} - Status: ${order['status']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminOrderDetailPage(order: order),
                            ),
                          ).then((_) => _loadOrders());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
