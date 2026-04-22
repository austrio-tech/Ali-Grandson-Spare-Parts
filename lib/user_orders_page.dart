import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'order_detail_page.dart';

// UserOrdersPage displays a history of all orders placed by the logged-in customer.
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  // We split orders into two lists: those still being processed and those finished.
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the orders from the database when the page loads.
    _loadOrders();
  }

  // Retrieves all orders for the current user and categorizes them.
  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final allOrders = await DatabaseHelper.instance.getUserOrders(username);
      if (mounted) {
        setState(() {
          // 'Pending' includes orders that are new, shipped, or processing.
          _pendingOrders = allOrders.where((order) => 
            order['status'] != 'Delivered' && order['status'] != 'Cancelled').toList();
          
          // 'Completed' includes orders that reached the final state (Delivered or Cancelled).
          _completedOrders = allOrders.where((order) => 
            order['status'] == 'Delivered' || order['status'] == 'Cancelled').toList();
          
          _isLoading = false; // Hide the loading spinner.
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
                // Display two distinct sections for orders.
                _buildOrderSection('Pending Orders', _pendingOrders),
                _buildOrderSection('Completed Orders', _completedOrders),
              ],
            ),
    );
  }

  // A helper function to build a section of the list (e.g., the "Pending" section).
  Widget _buildOrderSection(String title, List<Map<String, dynamic>> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title.
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
          // Creates a card for each order in the list.
          ...orders.map((order) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Text('Total: OMR ${order['total_price']} - ${order['status']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Clicking an order takes the user to a page with more details.
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
