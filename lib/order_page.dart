import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// OrderPage is where users provide their delivery address and payment info to finish their purchase.
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // GlobalKey helps validate the entire checkout form (checking if address/phone are empty).
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for delivery information.
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  // Controllers for credit card details (only used if user selects 'Card').
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Default payment mode is set to Cash on Delivery.
  String _paymentMode = 'Cash on Delivery';
  
  // Lists and variables to hold checkout data.
  List<Map<String, dynamic>> _cartItems = [];
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the items to be ordered and the user's saved phone number.
    _loadOrderData();
  }

  // Pre-fills data like phone number from user profile for convenience.
  Future<void> _loadOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    if (_username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(_username);
      if (user != null) {
        _phoneController.text = user['phone'] ?? '';
      }
      _cartItems = await DatabaseHelper.instance.getCartItems(_username);
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Calculates the sum of all items being ordered.
  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // This function is triggered when 'Confirm Order' is clicked.
  Future<void> _placeOrder() async {
    // 1. Check if all required fields are filled.
    if (_formKey.currentState!.validate()) {
      // 2. Prepare the order information for the database.
      final order = {
        'user_username': _username,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'special_instructions': _instructionsController.text,
        'payment_mode': _paymentMode,
        'total_price': _totalPrice,
        'status': 'Pending', // Initial status for every new order.
        'order_date': DateTime.now().toString(),
      };

      // 3. Save the order and individual items to the database.
      await DatabaseHelper.instance.placeOrder(order, _cartItems);

      // 4. Notify user and go back to the dashboard.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivery Address Input.
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Delivery Address *'),
                      validator: (value) => value!.isEmpty ? 'Enter delivery address' : null,
                    ),
                    const SizedBox(height: 15),
                    // Contact Phone Input.
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 15),
                    // Optional delivery notes.
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions (optional)',
                        hintText: 'e.g., Leave at the front door',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    // Payment selection section.
                    const Text('Payment Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ListTile(
                      title: const Text('Cash on Delivery'),
                      leading: Radio<String>(
                        value: 'Cash on Delivery',
                        groupValue: _paymentMode,
                        onChanged: (value) {
                          setState(() {
                            _paymentMode = value!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Card'),
                      leading: Radio<String>(
                        value: 'Card',
                        groupValue: _paymentMode,
                        onChanged: (value) {
                          setState(() {
                            _paymentMode = value!;
                          });
                        },
                      ),
                    ),
                    // Conditional section: Only shows card fields if 'Card' is selected.
                    if (_paymentMode == 'Card') ...[
                      const SizedBox(height: 15),
                      const Text('Card Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cardNameController,
                        decoration: const InputDecoration(labelText: 'Card Holder Name *'),
                        validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Enter name on card' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(labelText: 'Card Number *'),
                        keyboardType: TextInputType.number,
                        validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Enter card number' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryDateController,
                              decoration: const InputDecoration(labelText: 'Expiry (MM/YY) *'),
                              validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              decoration: const InputDecoration(labelText: 'CVV *'),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 25),
                    // Total bill display.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Amount: OMR ${_totalPrice.toStringAsFixed(3)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Button to submit the order.
                    ElevatedButton(
                      onPressed: _placeOrder,
                      child: const Text('Confirm Order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
