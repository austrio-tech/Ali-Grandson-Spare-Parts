import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/widgets/banner_carousel.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/user_view_product_page.dart';
import 'package:alis_grandson_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:alis_grandson_app/src/features/cart/presentation/pages/cart_page.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/user_orders_page.dart';
import 'package:alis_grandson_app/src/features/support/presentation/pages/faq_page.dart';
import 'package:alis_grandson_app/src/features/home/presentation/pages/home_page.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _displayName = '';
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? 'User';
    
    final user = await DatabaseHelper.instance.getUserByUsername(username);
    if (mounted) {
      setState(() {
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

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.searchProducts(keyword);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _navigateToViewProduct(int productId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => UserViewProductPage(productId: productId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _loadProducts();
      _loadCartCount();
    });
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('ALI GRANDSONS'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontSize: 18,
        ),
        actions: [
          _buildCartBadge(),
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: kPrimaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const BannerCarousel(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Text(
                      'PREMIUM CATALOG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: kSecondaryColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _products.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('No products found.')))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildModernProductCard(_products[index]),
                            childCount: _products.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: kSecondaryColor, size: 26),
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
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kAccentColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_cartItemCount',
                style: const TextStyle(
                  color: kPrimaryDark,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search parts, brands, or models...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kPrimaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _loadProducts();
                    },
                  )
                : null,
            fillColor: kSurfaceColor,
          ),
          onChanged: _searchProducts,
        ),
      ),
    );
  }

  Widget _buildModernProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kGreyLight, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToViewProduct(product['id'] as int),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'product_${product['id']}',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: kGrey100,
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: DatabaseHelper.instance.getProductImage(product['id'] as int),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                        );
                      }
                      return const Icon(Icons.image_outlined, color: kGreyMedium, size: 30);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['brand']?.toUpperCase() ?? 'GENUINE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kAccentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: kSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['description'] ?? '',
                      style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OMR ${product['price']}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (product['available'] as int) > 0 
                                ? kSuccessColor.withOpacity(0.1) 
                                : kErrorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (product['available'] as int) > 0 ? 'IN STOCK' : 'OUT OF STOCK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: (product['available'] as int) > 0 ? kSuccessColor : kErrorColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: kSurfaceColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              image: DecorationImage(
                image: AssetImage('lib/assets/Imgs/logo.png'),
                opacity: 0.03,
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: kPrimaryColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome,',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                Text(
                  _displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(Icons.explore_outlined, 'Browse Catalog', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.local_shipping_outlined, 'My Orders', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserOrdersPage()));
          }),
          _buildDrawerItem(Icons.person_outline_rounded, 'Account Settings', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())).then((_) => _loadDashboardData());
          }),
          _buildDrawerItem(Icons.help_center_outlined, 'Help & Support', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQPage()));
          }),
          const Spacer(),
          const Divider(indent: 24, endIndent: 24),
          _buildDrawerItem(Icons.logout_rounded, 'Sign Out', _logout, isDestructive: true),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: isDestructive ? kErrorColor : kSecondaryColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? kErrorColor : kSecondaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
