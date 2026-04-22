import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_product_page.dart';
import 'view_product_page.dart';

// ManageProductsPage allows administrators to view, search, and navigate to add or edit products.
class ManageProductsPage extends StatefulWidget {
  // Optional filter to show only 'out_of_stock' or 'low_stock' items.
  final String? filter;
  const ManageProductsPage({super.key, this.filter});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  // Controller for the search text box.
  final TextEditingController _searchController = TextEditingController();
  
  // List to store the products that will be displayed on the screen.
  List<Map<String, dynamic>> _products = [];
  
  // Loading state to show a progress spinner while fetching products from the database.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load products when the screen is first opened.
    _loadProducts();
  }

  // Fetches products from the database, applying filters if necessary.
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    // Request products from DatabaseHelper with the current filter.
    final products = await DatabaseHelper.instance.getProducts(filter: widget.filter);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  // Searches for products that match the keyword typed in the search box.
  Future<void> _searchProducts(String keyword) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    // Request filtered products from DatabaseHelper.
    final products = await DatabaseHelper.instance.searchProducts(keyword);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  // Navigates to the page where a new product can be created.
  void _navigateToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    ).then((_) => _loadProducts()); // Refresh the list when returning.
  }

  // Navigates to the detailed view of a specific product.
  void _navigateToViewProduct(int productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewProductPage(productId: productId),
      ),
    ).then((_) => _loadProducts()); // Refresh the list when returning.
  }

  @override
  Widget build(BuildContext context) {
    // Determine the page title based on the active filter.
    String title = 'Manage Products';
    if (widget.filter == 'out_of_stock') title = 'Out of Stock Products';
    if (widget.filter == 'low_stock') title = 'Low Stock Products';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Button to add a new product.
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // The Search Bar at the top of the list.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _searchProducts, // Triggers search on every keystroke.
            ),
          ),
          // The main list area.
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: InkWell(
                              onTap: () => _navigateToViewProduct(product['id'] as int),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // Product Image loaded from the database bytes.
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: FutureBuilder<Uint8List?>(
                                        future: DatabaseHelper.instance.getProductImage(product['id'] as int),
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
                                    const SizedBox(width: 10),
                                    // Product details column.
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'No Name',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            product['description'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Price: OMR ${product['price']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 5),
                                          // Availability status with color coding (Red for out of stock, Orange for low stock).
                                          Text(
                                            'Available: ${product['available']}',
                                            style: TextStyle(
                                              color: (product['available'] as int) == 0 
                                                ? Colors.red 
                                                : (product['available'] as int) < 10 
                                                  ? Colors.orange 
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
