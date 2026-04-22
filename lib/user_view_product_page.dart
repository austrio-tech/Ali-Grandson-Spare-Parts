import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// UserViewProductPage allows customers to see all details of a spare part and add it to their cart.
class UserViewProductPage extends StatefulWidget {
  final int productId;

  const UserViewProductPage({super.key, required this.productId});

  @override
  State<UserViewProductPage> createState() => _UserViewProductPageState();
}

class _UserViewProductPageState extends State<UserViewProductPage> {
  // Map to store product details fetched from the database.
  Map<String, dynamic>? _product;
  
  // Loading state to show a spinner during data fetch.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load product information when the page is opened.
    _loadProduct();
  }

  // Fetches product data using its unique ID.
  Future<void> _loadProduct() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final product = await DatabaseHelper.instance.getProduct(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  // Opens a pop-up dialog to ask the user how many items they want to buy.
  void _showQuantityDialog() {
    final TextEditingController quantityController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                // Check if the requested quantity is available in stock.
                if (quantity <= (_product!['available'] as int)) {
                  Navigator.pop(context); // Close dialog.
                  _addToCart(quantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough stock available.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity.')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Adds the selected product and quantity to the user's shopping cart.
  Future<void> _addToCart(int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';

    if (username.isNotEmpty) {
      await DatabaseHelper.instance.addToCart(username, widget.productId, quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart!')),
      );
      Navigator.of(context).pop(); // Go back to the dashboard.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image displayed at the top.
                      SizedBox(
                        height: 200,
                        child: FutureBuilder<Uint8List?>(
                          future: DatabaseHelper.instance.getProductImage(widget.productId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            } else {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50, color: Colors.grey),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Technical details like Name, Brand, and Price.
                      _buildDetailRow('Name', _product!['name'] ?? 'N/A'),
                      _buildDetailRow('Description', _product!['description'] ?? 'N/A'),
                      _buildDetailRow('Type', _product!['type'] ?? 'N/A'),
                      _buildDetailRow('Brand', _product!['brand'] ?? 'N/A'),
                      _buildDetailRow('Model/Year', _product!['model'] ?? 'N/A'),
                      _buildDetailRow('Price', 'OMR ${_product!['price']}'),
                      _buildDetailRow('Available', '${_product!['available']}'),
                      const SizedBox(height: 30),
                      // Action buttons: Back and Add to Cart.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: const Text('Back'),
                          ),
                          // "Add to Cart" button is disabled (null) if the product is out of stock.
                          ElevatedButton(
                            onPressed: (_product!['available'] as int) > 0 ? _showQuantityDialog : null,
                            child: const Text('Add to Cart'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }

  // A helper function to build a clean looking row for data like "Brand: NGK".
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
