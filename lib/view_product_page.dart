import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'edit_product_page.dart';

// ViewProductPage is an administrative screen that shows all the details of a single spare part.
class ViewProductPage extends StatefulWidget {
  final int productId;

  const ViewProductPage({super.key, required this.productId});

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  // Holds the product data retrieved from the database.
  Map<String, dynamic>? _product;
  
  // Loading state to show a spinner while fetching data.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the product details when the page is opened.
    _loadProduct();
  }

  // Fetches the product information using its unique ID.
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

  // Deletes the product from the store after getting confirmation from the admin.
  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to remove this product? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteProduct(widget.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed successfully!')),
      );
      Navigator.of(context).pop(); // Go back to the product list.
    }
  }

  // Opens the edit page for this specific product.
  void _navigateToEditProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductPage(productId: widget.productId),
      ),
    ).then((_) => _loadProduct()); // Refresh the details when returning from editing.
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
                      // Display the product image at the top.
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
                      // List all the technical details of the spare part.
                      _buildDetailRow('Name', _product!['name'] ?? 'N/A'),
                      _buildDetailRow('Description', _product!['description'] ?? 'N/A'),
                      _buildDetailRow('Type', _product!['type'] ?? 'N/A'),
                      _buildDetailRow('Brand', _product!['brand'] ?? 'N/A'),
                      _buildDetailRow('Model/Year', _product!['model'] ?? 'N/A'),
                      _buildDetailRow('Price', 'OMR ${_product!['price']}'),
                      _buildDetailRow('Available', '${_product!['available']}'),
                      const SizedBox(height: 30),
                      // Buttons to either Edit or Remove the product.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _navigateToEditProduct,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                          ElevatedButton.icon(
                            onPressed: _deleteProduct,
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }

  // A helper function to build a clean looking row for data like "Price: OMR 5.000".
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
