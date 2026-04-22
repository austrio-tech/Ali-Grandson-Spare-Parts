// This is the main entry point of the Flutter application.
// It imports necessary packages and files for the app to function.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_user.dart';
import 'login_admin.dart';
import 'signup_user.dart';
import 'app_colors.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'Product_Data/product_data.dart';

// The main function is where the execution starts.
void main() async {
  // Ensures that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed the database with default products if it's the first time running.
  // This helps in having some data available for the user to see immediately.
  await ProductData.seedDatabase();

  // SharedPreferences is used to store small amounts of data locally on the device.
  // Here, we check if a user or admin is already logged in from a previous session.
  final prefs = await SharedPreferences.getInstance();
  final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;
  final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

  // Runs the main MyApp widget, passing the login status.
  runApp(MyApp(isAdminLoggedIn: isAdminLoggedIn, isUserLoggedIn: isUserLoggedIn));
}

// MyApp is the root widget of the application.
// It sets up the overall theme and navigation routes.
class MyApp extends StatelessWidget {
  final bool isAdminLoggedIn;
  final bool isUserLoggedIn;
  
  // Constructor for MyApp to receive login status.
  const MyApp({super.key, required this.isAdminLoggedIn, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali Grandsons Spare Parts', // The title of the application.
      // Defining the global visual theme for the app.
      theme: ThemeData(
        primaryColor: maroon, // Main color used throughout the app.
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: maroon,
          secondary: silver,
          onPrimary: Colors.white, // Color used for text/icons on top of the primary color.
        ),
        scaffoldBackgroundColor: Colors.grey[200], // Background color of the screens.
        // Customizing the appearance of the top AppBar.
        appBarTheme: const AppBarTheme(
          backgroundColor: maroon,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // Customizing the default look for buttons.
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
        // Customizing the look of input fields (like text boxes for login).
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
      // Determines which screen to show first based on login status.
      home: _getInitialScreen(),
      // Named routes for easy navigation to specific pages.
      routes: {
        '/login_user': (context) => const LoginUserPage(),
        '/login_admin': (context) => const LoginAdminPage(),
        '/signup_user': (context) => const SignupUserPage(),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }

  // Helper function to decide the starting page.
  Widget _getInitialScreen() {
    if (isAdminLoggedIn) {
      return const AdminDashboard(); // Show admin dashboard if admin is logged in.
    } else if (isUserLoggedIn) {
      return const UserDashboard(); // Show user dashboard if user is logged in.
    } else {
      return const HomePage(); // Show home/welcome page if no one is logged in.
    }
  }
}

// HomePage is the first screen shown to guests.
// It offers options to login as a user, admin, or sign up.
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
          // Column stacks its children vertically.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Displays the company logo in a circular frame.
              CircleAvatar(
                radius: 80,
                backgroundColor: maroon,
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'lib/Imgs/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40), // Adds vertical spacing.
              // Button to go to User Login page.
              ElevatedButton(
                key: const ValueKey('userLoginButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login_user');
                },
                child: const Text('User Login'),
              ),
              const SizedBox(height: 20),
              // Button to go to Admin Login page.
              ElevatedButton(
                key: const ValueKey('adminLoginButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login_admin');
                },
                child: const Text('Admin Login'),
              ),
              const SizedBox(height: 20),
              // Button to go to User Signup page.
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
