import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'admin_order_detail_page.dart';

// ManageOrdersPage is an administrative screen for viewing and filtering all customer orders.
class ManageOrdersPage extends StatefulWidget {
  // Optional filter to show only 'pending' or 'completed' orders.
  final String? filter;
  const ManageOrdersPage({super.key, this.filter});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  // A list to store the order records fetched from the database.
  List<Map<String, dynamic>> _orders = [];
  
  // Loading state to show a spinner while fetching data.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the orders as soon as the admin opens this page.
    _loadOrders();
  }

  // Fetches orders from the 'orders' table, potentially filtered by status.
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    // Request filtered or all orders from DatabaseHelper.
    final orders = await DatabaseHelper.instance.getAllOrders(filter: widget.filter);
    setState(() {
      _orders = orders;
      _isLoading = false; // Hide the loading spinner.
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic title based on the active filter.
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
                  // Creates a scrolling list of all matching orders.
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        // Display order ID and the username of the customer who placed it.
                        title: Text('Order #${order['id']} - ${order['user_username']}'),
                        // Display total price and current status (e.g., Pending, Shipped, Delivered).
                        subtitle: Text('Total: OMR ${order['total_price']} - Status: ${order['status']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Clicking an order takes the admin to a detailed view with status controls.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminOrderDetailPage(order: order),
                            ),
                          ).then((_) => _loadOrders()); // Refresh the list when returning.
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
