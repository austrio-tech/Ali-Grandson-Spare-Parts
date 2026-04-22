import 'package:flutter/material.dart';
import 'database_helper.dart';

class AdminOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AdminOrderDetailPage({super.key, required this.order});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;
  late String _selectedStatus;
  final List<String> _statuses = ['Pending', 'Ready', 'In Delivery', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order['status'];
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    final items = await DatabaseHelper.instance.getOrderItems(widget.order['id'] as int);
    if (mounted) {
      setState(() {
        _orderItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus != null) {
      await DatabaseHelper.instance.updateOrderStatus(widget.order['id'] as int, newStatus);
      setState(() {
        _selectedStatus = newStatus;
      });
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
                  _buildSectionTitle('Order Summary'),
                  _buildDetailRow('Customer', widget.order['user_username']),
                  _buildDetailRow('Placed On', widget.order['order_date']),
                  if (widget.order['completion_date'] != null)
                    _buildDetailRow('Completed On', widget.order['completion_date']),
                  _buildDetailRow('Payment Mode', widget.order['payment_mode']),
                  _buildDetailRow('Total Price', 'OMR ${widget.order['total_price']}'),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Shipping Information'),
                  _buildDetailRow('Address', widget.order['address']),
                  _buildDetailRow('Phone', widget.order['phone']),
                  if (widget.order['special_instructions'] != null && (widget.order['special_instructions'] as String).isNotEmpty)
                    _buildDetailRow('Instructions', widget.order['special_instructions']),

                  const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
