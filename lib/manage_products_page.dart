import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_product_page.dart';
import 'view_product_page.dart';

class ManageProductsPage extends StatefulWidget {
  final String? filter;
  const ManageProductsPage({super.key, this.filter});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final products = await DatabaseHelper.instance.getProducts(filter: widget.filter);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts(String keyword) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final products = await DatabaseHelper.instance.searchProducts(keyword);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _navigateToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    ).then((_) => _loadProducts());
  }

  void _navigateToViewProduct(int productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewProductPage(productId: productId),
      ),
    ).then((_) => _loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Manage Products';
    if (widget.filter == 'out_of_stock') title = 'Out of Stock Products';
    if (widget.filter == 'low_stock') title = 'Low Stock Products';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
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
              onChanged: _searchProducts,
            ),
          ),
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
