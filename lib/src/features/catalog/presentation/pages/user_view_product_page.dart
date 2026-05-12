// ============================================================
// user_view_product_page.dart — Customer: Product Detail Screen
// ============================================================
// Shows the customer a full-screen view of a single product with
// a large expanding header image and a Hero animation from the
// product list card.
//
// Bottom action bar:
//   • "ADD TO CART" button if the product is in stock.
//   • "OUT OF STOCK" disabled button otherwise.
//
// Tapping ADD TO CART opens a dialog asking for the desired
// quantity (validated against available stock), then calls
// DatabaseHelper.addToCart() and returns to the catalog.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Customer-facing product detail and add-to-cart screen.
class UserViewProductPage extends StatefulWidget {
  /// The database id of the product to display.
  final int productId;

  const UserViewProductPage({super.key, required this.productId});

  @override
  State<UserViewProductPage> createState() => _UserViewProductPageState();
}

class _UserViewProductPageState extends State<UserViewProductPage> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final product = await DatabaseHelper.instance.getProduct(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  void _showQuantityDialog() {
    final TextEditingController quantityController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many units would you like to add?'),
            const SizedBox(height: 20),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                if (quantity <= (_product!['available'] as int)) {
                  Navigator.pop(context);
                  _addToCart(quantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough stock available.'), backgroundColor: kErrorColor),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';

    if (username.isNotEmpty) {
      await DatabaseHelper.instance.addToCart(username, widget.productId, quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart successfully!'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found.'))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _product!['brand']?.toUpperCase() ?? 'GENUINE',
                                        style: const TextStyle(
                                          color: kAccentColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _product!['name'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kSecondaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'OMR ${_product!['price']}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildAvailabilityBadge(),
                            const SizedBox(height: 32),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(
                              _product!['description'] ?? 'No description available.',
                              style: const TextStyle(fontSize: 16, color: kTextSecondary, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildSpecRow('Type', _product!['type'] ?? 'General'),
                            _buildSpecRow('Compatibility', _product!['model'] ?? 'Universal'),
                            _buildSpecRow('Part ID', '#${widget.productId.toString().padLeft(6, '0')}'),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _product != null ? _buildBottomAction() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: kPrimaryColor,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${widget.productId}',
          child: FutureBuilder<Uint8List?>(
            future: DatabaseHelper.instance.getProductImage(widget.productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              }
              return Container(color: kGreyLight, child: const Icon(Icons.image, size: 80, color: kGreyMedium));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    bool inStock = (_product!['available'] as int) > 0;
    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle_rounded : Icons.error_rounded,
          color: inStock ? kSuccessColor : kErrorColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          inStock ? 'In Stock (${_product!['available']} units)' : 'Out of Stock',
          style: TextStyle(
            color: inStock ? kSuccessColor : kErrorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: kTextSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    bool inStock = (_product!['available'] as int) > 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: inStock ? _showQuantityDialog : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: inStock ? kPrimaryColor : kGreyMedium,
            disabledBackgroundColor: kGreyMedium,
          ),
          child: Text(inStock ? 'ADD TO CART' : 'OUT OF STOCK'),
        ),
      ),
    );
  }
}
