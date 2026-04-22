import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'order_page.dart';

// CartPage shows the list of items the user has selected to buy.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // A list to store items currently in the user's cart.
  List<Map<String, dynamic>> _cartItems = [];
  
  // Loading state to show a spinner while fetching data.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load items from the database when the cart page is opened.
    _loadCartItems();
  }

  // Fetches items from the 'cart' table in the database for the logged-in user.
  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final items = await DatabaseHelper.instance.getCartItems(username);
      if (mounted) {
        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
      }
    }
  }

  // Increases or decreases the quantity of an item in the cart.
  Future<void> _updateQuantity(Map<String, dynamic> item, int newQuantity) async {
    final available = item['available'] as int;
    
    // Checks if the requested quantity exceeds the actual stock.
    if (newQuantity > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $available items available in stock.')),
      );
      return;
    }

    // Only update if the quantity is at least 1.
    if (newQuantity > 0) {
      await DatabaseHelper.instance.updateCartItem(item['cart_id'], newQuantity);
      _loadCartItems(); // Refresh the list.
    }
  }

  // Removes an item completely from the cart.
  Future<void> _deleteItem(int cartId) async {
    await DatabaseHelper.instance.deleteCartItem(cartId);
    _loadCartItems(); // Refresh the list.
  }

  // Calculates the total price of all items in the cart.
  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : Column(
                  children: [
                    // Flexible list area for cart items.
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              // Displays the product image.
                              leading: SizedBox(
                                width: 60,
                                height: 60,
                                child: FutureBuilder<Uint8List?>(
                                  future: DatabaseHelper.instance.getProductImage(item['id'] as int),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                    } else {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      );
                                    }
                                  },
                                ),
                              ),
                              title: Text(item['name'] ?? 'No Name'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price: OMR ${item['price']}'),
                                  Text('Stock: ${item['available']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              // Buttons to change quantity or remove the item.
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _updateQuantity(item, item['quantity'] - 1),
                                  ),
                                  Text(item['quantity'].toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateQuantity(item, item['quantity'] + 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteItem(item['cart_id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom summary section with Total and Checkout button.
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: OMR ${_totalPrice.toStringAsFixed(3)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Navigates to the Order details page to finalize purchase.
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderPage()));
                            },
                            child: const Text('Place Order'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
