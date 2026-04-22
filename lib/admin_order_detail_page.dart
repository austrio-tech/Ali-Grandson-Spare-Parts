import 'package:flutter/material.dart';
import 'database_helper.dart';

// AdminOrderDetailPage is a detailed view for store managers to review an order and update its progress.
class AdminOrderDetailPage extends StatefulWidget {
  // 'order' contains the high-level data like order ID and customer name.
  final Map<String, dynamic> order;

  const AdminOrderDetailPage({super.key, required this.order});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  // A list to hold the specific products (items) that make up this order.
  List<Map<String, dynamic>> _orderItems = [];
  
  // Loading state to show a spinner while data is being loaded from the database.
  bool _isLoading = true;
  
  // Keeps track of the current status (e.g., 'Pending') chosen from the dropdown menu.
  late String _selectedStatus;
  
  // These are the possible stages an order can go through.
  final List<String> _statuses = ['Pending', 'Ready', 'In Delivery', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    // Set the initial status based on what's already saved in the database.
    _selectedStatus = widget.order['status'];
    // Load the full list of products in this order.
    _loadOrderItems();
  }

  // Fetches the items associated with this order ID.
  Future<void> _loadOrderItems() async {
    final items = await DatabaseHelper.instance.getOrderItems(widget.order['id'] as int);
    if (mounted) {
      setState(() {
        _orderItems = items;
        _isLoading = false; // Hide the loading indicator.
      });
    }
  }

  // This function updates the order's status in the database when the admin changes the dropdown.
  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus != null) {
      await DatabaseHelper.instance.updateOrderStatus(widget.order['id'] as int, newStatus);
      setState(() {
        _selectedStatus = newStatus;
      });
      // Show a confirmation message at the bottom.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order['id']} Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Update Section: A dropdown to change the current state of the order.
                  _buildSectionTitle('Change Status'),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: _updateStatus,
                  ),
                  const SizedBox(height: 20),
                  
                  // 2. Summary Section: Shows basic details like customer name and price.
                  _buildSectionTitle('Order Summary'),
                  _buildDetailRow('Customer', widget.order['user_username']),
                  _buildDetailRow('Placed On', widget.order['order_date']),
                  if (widget.order['completion_date'] != null)
                    _buildDetailRow('Completed On', widget.order['completion_date']),
                  _buildDetailRow('Payment Mode', widget.order['payment_mode']),
                  _buildDetailRow('Total Price', 'OMR ${widget.order['total_price']}'),
                  
                  const SizedBox(height: 20),
                  
                  // 3. Shipping Info Section: Where the order needs to be delivered.
                  _buildSectionTitle('Shipping Information'),
                  _buildDetailRow('Address', widget.order['address']),
                  _buildDetailRow('Phone', widget.order['phone']),
                  // Only show notes if the customer left any.
                  if (widget.order['special_instructions'] != null && (widget.order['special_instructions'] as String).isNotEmpty)
                    _buildDetailRow('Instructions', widget.order['special_instructions']),

                  const SizedBox(height: 20),
                  
                  // 4. Order Items Section: Lists all products bought in this transaction.
                  _buildSectionTitle('Items'),
                  ..._orderItems.map((item) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(item['product_name'] ?? 'Unknown Product'),
                          subtitle: Text('Quantity: ${item['quantity']}'),
                          trailing: Text('OMR ${item['price']}'),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  // A helper function to create a bold section title.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  // A helper function to build a clean looking row for data like "Address: Muscat, Oman".
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Aligns all values vertically.
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
