import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'main.dart';
import 'database_helper.dart';
import 'user_view_product_page.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'user_orders_page.dart';
import 'faq_page.dart';

// UserDashboard is the main screen for a logged-in user.
// It allows users to browse products, search, view their cart, and access their profile.
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  // Controller to handle text input in the search bar.
  final TextEditingController _searchController = TextEditingController();
  
  // List to store products fetched from the database.
  List<Map<String, dynamic>> _products = [];
  
  // Loading state to show a spinner while data is being fetched.
  bool _isLoading = true;
  
  // Stores the name to display in the drawer.
  String _displayName = '';
  
  // Keeps track of how many items are currently in the user's cart.
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data when the dashboard opens.
    _loadDashboardData();
  }

  // Fetches user info, products, and cart count.
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? 'User';
    
    // Get full user details from the database using the stored username.
    final user = await DatabaseHelper.instance.getUserByUsername(username);
    if (mounted) {
      setState(() {
        // Use the user's name if available, otherwise fallback to username.
        if (user != null && user['name'] != null && (user['name'] as String).isNotEmpty) {
          _displayName = user['name'];
        } else {
          _displayName = username;
        }
      });
    }
    _loadProducts();
    _loadCartCount();
  }

  // Counts how many items are in the user's cart to show on the cart icon.
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final items = await DatabaseHelper.instance.getCartItems(username);
      if (mounted) {
        setState(() {
          _cartItemCount = items.length;
        });
      }
    }
  }

  // Fetches all products from the database.
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final products = await DatabaseHelper.instance.getProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  // Filters products based on a search keyword.
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

  // Opens the detailed view for a selected product.
  void _navigateToViewProduct(int productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserViewProductPage(productId: productId),
      ),
    ).then((_) {
      // Refresh products and cart count when returning from the product page.
      _loadProducts();
      _loadCartCount();
    });
  }

  // Logs out the user by clearing saved login data and returning to the home page.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_username');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Cart icon with a badge showing the number of items.
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  ).then((_) => _loadCartCount());
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      // Side menu (Drawer) for navigation to other sections.
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 250,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: maroon),
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
                            Image.asset('lib/Imgs/logo.png', height: 150),
                            const SizedBox(height: 10),
                            Text(
                              'Welcome $_displayName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
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
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Products'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UserOrdersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _loadDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQs & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FAQPage()),
                );
              },
            ),
            const Divider(), // Horizontal line to separate menu items.
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // A scrolling banner at the top of the dashboard.
          const BannerCarousel(),
          const SizedBox(height: 10),
          // Search box to filter products by name.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _searchProducts,
            ),
          ),
          const SizedBox(height: 10),
          // Display the list of products or a loading indicator.
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
                                    // Display product image.
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
                                    // Display product details like name, price, and availability.
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'No Name',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                          Text('Available: ${product['available']}'),
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

// BannerCarousel is a widget that shows auto-sliding promotional images.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;
  
  // List of image paths for the banner.
  final List<String> _banners = [
    'lib/Banner_Imgs/banner1.png',
    'lib/Banner_Imgs/banner2.png',
    'lib/Banner_Imgs/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    // Start a timer that automatically changes the banner page every 1.5 seconds.
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    // Clean up the timer and controller when the widget is removed.
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 1, // Sets a fixed width-to-height ratio for the banner.
      child: PageView.builder(
        controller: _pageController,
        itemCount: _banners.length,
        onPageChanged: (int index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                _banners[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
