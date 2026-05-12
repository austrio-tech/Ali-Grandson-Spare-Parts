// ============================================================
// order_page.dart — Checkout / Order Placement Screen
// ============================================================
// Presents a checkout form after the user taps "Proceed to Checkout"
// from the cart.  The user enters:
//   • Delivery address and contact phone number.
//   • Optional special instructions (e.g. "Leave with neighbour").
//   • Payment method: Cash on Delivery or Card.
//     — Selecting Card reveals additional card detail fields.
//
// On confirmation:
//   1. The order is saved to the database via placeOrder() which
//      atomically deducts stock and clears the cart.
//   2. Email notifications are sent to the admin (new order) and,
//      if stock is now low/zero, a stock alert is also emailed.
//   3. The user is returned to the dashboard.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Checkout screen where users provide delivery details and confirm the order.
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  final EmailService _emailService = EmailService();

  String _paymentMode = 'Cash on Delivery';
  List<Map<String, dynamic>> _cartItems = [];
  String _username = '';
  String _customerName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    if (_username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(_username);
      if (user != null) {
        _phoneController.text = user['phone'] ?? '';
        _customerName = user['name'] ?? _username;
      }
      _cartItems = await DatabaseHelper.instance.getCartItems(_username);
    }
    setState(() => _isLoading = false);
  }

  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final order = {
        'user_username': _username,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'special_instructions': _instructionsController.text,
        'payment_mode': _paymentMode,
        'total_price': _totalPrice,
        'status': 'Pending',
        'order_date': DateTime.now().toString(),
      };

      final orderId = await DatabaseHelper.instance.placeOrder(order, _cartItems);

      // Send Emails
      _sendAdminNotifications(orderId.toString());

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! Notifications sent to Admin.'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _sendAdminNotifications(String orderId) async {
    final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? 'admin@example.com';

    // 1. New Order Notification
    await _emailService.sendGoogleEmail(
      recipientEmails: adminEmail,
      subject: 'New Order Received #$orderId',
      htmlBody: EmailTemplates.newOrderAdmin(orderId, _customerName, 'OMR ${_totalPrice.toStringAsFixed(3)}'),
    );

    // 2. Stock Checks
    for (var item in _cartItems) {
      final product = await DatabaseHelper.instance.getProduct(item['id']);
      if (product != null) {
        final available = product['available'] as int;
        if (available == 0) {
          await _emailService.sendGoogleEmail(
            recipientEmails: adminEmail,
            subject: 'Out of Stock Alert: ${product['name']}',
            htmlBody: EmailTemplates.outOfStockAdmin(product['name']),
          );
        } else if (available < 5) {
          await _emailService.sendGoogleEmail(
            recipientEmails: adminEmail,
            subject: 'Low Stock Alert: ${product['name']}',
            htmlBody: EmailTemplates.lowStockAdmin(product['name'], available),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('CHECKOUT'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(Icons.location_on_outlined, 'Delivery Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Delivery Address',
                        hintText: 'Building, Street, Area, City',
                      ),
                      maxLines: 2,
                      validator: (value) => value!.isEmpty ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Please enter phone' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions',
                        hintText: 'e.g. Leave with neighbor',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(Icons.payment_outlined, 'Payment Method'),
                    const SizedBox(height: 16),
                    _buildPaymentOption('Cash on Delivery', Icons.payments_outlined),
                    const SizedBox(height: 12),
                    _buildPaymentOption('Card', Icons.credit_card_outlined),
                    if (_paymentMode == 'Card') _buildCardDetails(),
                    const SizedBox(height: 32),
                    _buildOrderSummary(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        shadowColor: kPrimaryColor.withOpacity(0.3),
                        elevation: 10,
                      ),
                      child: const Text('CONFIRM & PLACE ORDER'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String mode, IconData icon) {
    bool isSelected = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kPrimaryColor : kGreyLight, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
            const SizedBox(width: 16),
            Text(
              mode,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? kPrimaryColor : kSecondaryColor,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetails() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGreyLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _cardNameController,
            decoration: const InputDecoration(labelText: 'Card Holder Name'),
            validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(labelText: 'Card Number', prefixIcon: Icon(Icons.credit_card)),
            keyboardType: TextInputType.number,
            validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                  validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  validator: (value) => _paymentMode == 'Card' && (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Total', style: TextStyle(color: Colors.white70)),
              Text('OMR ${_totalPrice.toStringAsFixed(3)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.white70)),
              Text('FREE', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'OMR ${_totalPrice.toStringAsFixed(3)}',
                style: const TextStyle(color: kAccentColor, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
