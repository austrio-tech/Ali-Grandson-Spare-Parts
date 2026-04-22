import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_user.dart';
import 'login_admin.dart';
import 'signup_user.dart';
import 'app_colors.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'Product_Data/product_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed the database with default products
  await ProductData.seedDatabase();

  final prefs = await SharedPreferences.getInstance();
  final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;
  final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

  runApp(MyApp(isAdminLoggedIn: isAdminLoggedIn, isUserLoggedIn: isUserLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isAdminLoggedIn;
  final bool isUserLoggedIn;
  const MyApp({super.key, required this.isAdminLoggedIn, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali Grandsons Spare Parts',
      theme: ThemeData(
        primaryColor: maroon,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: maroon,
          secondary: silver,
          onPrimary: Colors.white, // For text on primary color
        ),
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          backgroundColor: maroon,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroon,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: silver),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: maroon),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      home: _getInitialScreen(),
      routes: {
        '/login_user': (context) => const LoginUserPage(),
        '/login_admin': (context) => const LoginAdminPage(),
        '/signup_user': (context) => const SignupUserPage(),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }

  Widget _getInitialScreen() {
    if (isAdminLoggedIn) {
      return const AdminDashboard();
    } else if (isUserLoggedIn) {
      return const UserDashboard();
    } else {
      return const HomePage();
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ali Grandsons Spare Parts'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CircleAvatar(
                radius: 80,
                backgroundColor: maroon,
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0), // Add padding around the image
                    child: Image.asset(
                      'lib/Imgs/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                key: const ValueKey('userLoginButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login_user');
                },
                child: const Text('User Login'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const ValueKey('adminLoginButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login_admin');
                },
                child: const Text('Admin Login'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const ValueKey('userSignupButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/signup_user');
                },
                child: const Text('User Signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
