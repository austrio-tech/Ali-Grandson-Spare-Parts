import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'order_detail_page.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final allOrders = await DatabaseHelper.instance.getUserOrders(username);
      if (mounted) {
        setState(() {
          // Pending includes everything that isn't Delivered or Cancelled
          _pendingOrders = allOrders.where((order) => 
            order['status'] != 'Delivered' && order['status'] != 'Cancelled').toList();
          
          // Completed includes Delivered and Cancelled
          _completedOrders = allOrders.where((order) => 
            order['status'] == 'Delivered' || order['status'] == 'Cancelled').toList();
          
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildOrderSection('Pending Orders', _pendingOrders),
                _buildOrderSection('Completed Orders', _completedOrders),
              ],
            ),
    );
  }

  Widget _buildOrderSection(String title, List<Map<String, dynamic>> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No orders found.'),
          )
        else
          ...orders.map((order) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Text('Total: OMR ${order['total_price']} - ${order['status']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(order: order),
                      ),
                    );
                  },
                ),
              )),
      ],
    );
  }
}
