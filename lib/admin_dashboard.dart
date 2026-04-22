import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'main.dart';
import 'manage_products_page.dart';
import 'manage_users_page.dart';
import 'manage_orders_page.dart';
import 'manage_faqs_page.dart';
import 'database_helper.dart';

// AdminDashboard is the main control center for the store administrator.
// It provides a summary of users, products, orders, and total revenue.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Variables to hold statistics shown on the dashboard cards.
  int _userCount = 0;
  int _productCount = 0;
  int _outOfStockCount = 0;
  int _lowStockCount = 0;
  int _pendingOrderCount = 0;
  int _completedOrderCount = 0;
  double _totalRevenue = 0.0;
  String _adminEmail = '';

  @override
  void initState() {
    super.initState();
    // Load the statistics from the database as soon as the dashboard is opened.
    _loadDashboardData();
  }

  // Fetches various counts and totals from the database to update the UI.
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('admin_email') ?? 'Admin';
    
    final db = DatabaseHelper.instance;
    // Running multiple database queries to get current store status.
    final userCount = await db.getUsersCount();
    final productCount = await db.getProductsCount();
    final outOfStockCount = await db.getOutOfStockCount();
    final lowStockCount = await db.getLowStockCount();
    final pendingCount = await db.getPendingOrdersCount();
    final completedCount = await db.getCompletedOrdersCount();
    final revenue = await db.getTotalRevenue();

    if (mounted) {
      setState(() {
        _adminEmail = email;
        _userCount = userCount;
        _productCount = productCount;
        _outOfStockCount = outOfStockCount;
        _lowStockCount = lowStockCount;
        _pendingOrderCount = pendingCount;
        _completedOrderCount = completedCount;
        _totalRevenue = revenue;
      });
    }
  }

  // Logs out the admin by clearing saved credentials and going back to the home screen.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_logged_in');
    await prefs.remove('admin_email');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      // Drawer is the side menu that slides out from the left.
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // The top section of the side menu, often containing a logo or user info.
            SizedBox(
              height: 250,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: maroon,
                ),
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              'lib/Imgs/logo.png',
                              height: 150,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Small button to close the drawer.
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation links to different management pages.
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Just close the drawer as we are already on Dashboard.
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Manage Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageUsersPage())).then((_) => _loadDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.production_quantity_limits),
              title: const Text('Manage Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageProductsPage())).then((_) => _loadDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Manage Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageOrdersPage())).then((_) => _loadDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Manage FAQs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageFAQsPage()));
              },
            ),
            const Divider(), // A visual line separator.
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      // The main content of the dashboard: a grid of summary cards.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two cards per row.
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard('Users', _userCount.toString(), Icons.person, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageUsersPage())).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Products', _productCount.toString(), Icons.shopping_bag, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageProductsPage())).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Out of Stock', _outOfStockCount.toString(), Icons.error_outline, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageProductsPage(filter: 'out_of_stock'))).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Low Stock', _lowStockCount.toString(), Icons.warning_amber_rounded, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageProductsPage(filter: 'low_stock'))).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Pending Orders', _pendingOrderCount.toString(), Icons.hourglass_empty, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageOrdersPage(filter: 'pending'))).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Completed Orders', _completedOrderCount.toString(), Icons.check_circle, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageOrdersPage(filter: 'completed'))).then((_) => _loadDashboardData());
            }),
            _buildDashboardCard('Total Revenue', 'OMR ${_totalRevenue.toStringAsFixed(2)}', Icons.payments, () {}),
          ],
        ),
      ),
    );
  }

  // A helper function to create a uniform look for the dashboard summary cards.
  Widget _buildDashboardCard(String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
