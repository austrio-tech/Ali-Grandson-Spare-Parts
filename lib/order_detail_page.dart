import 'package:flutter/material.dart';
import 'database_helper.dart';

// OrderDetailPage shows a comprehensive breakdown of a single order.
// It displays what was bought, where it's going, and the current status.
class OrderDetailPage extends StatefulWidget {
  // The 'order' variable contains the general summary of the order passed from the list page.
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // A list to store the specific items (products) that belong to this order.
  List<Map<String, dynamic>> _orderItems = [];
  
  // Loading state to show a spinner while fetching the items from the database.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the specific items for this order when the page opens.
    _loadOrderItems();
  }

  // Retrieves the list of products associated with this specific order ID.
  Future<void> _loadOrderItems() async {
    final items = await DatabaseHelper.instance.getOrderItems(widget.order['id'] as int);
    if (mounted) {
      setState(() {
        _orderItems = items;
        _isLoading = false; // Hide the loading spinner.
      });
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
                  // 1. General Order Summary (Status, Date, Payment).
                  _buildSectionTitle('Order Summary'),
                  _buildDetailRow('Status', widget.order['status']),
                  _buildDetailRow('Placed On', widget.order['order_date']),
                  // Only show completion date if the order is actually finished.
                  if (widget.order['completion_date'] != null)
                    _buildDetailRow('Completed On', widget.order['completion_date']),
                  _buildDetailRow('Payment Mode', widget.order['payment_mode']),
                  _buildDetailRow('Total Price', 'OMR ${widget.order['total_price']}'),
                  
                  const SizedBox(height: 20),
                  // 2. Shipping/Delivery Details.
                  _buildSectionTitle('Shipping Information'),
                  _buildDetailRow('Address', widget.order['address']),
                  _buildDetailRow('Phone', widget.order['phone']),
                  // Only show instructions if the user actually provided any.
                  if (widget.order['special_instructions'] != null && (widget.order['special_instructions'] as String).isNotEmpty)
                    _buildDetailRow('Instructions', widget.order['special_instructions']),

                  const SizedBox(height: 20),
                  // 3. List of Products bought in this order.
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

  // A helper function to build a clean looking row for data like "Status: Pending".
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for labels to keep them aligned.
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
