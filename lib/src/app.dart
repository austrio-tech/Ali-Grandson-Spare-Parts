import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/features/home/presentation/pages/home_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/login_user_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/login_admin_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/signup_user_page.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/user_dashboard_page.dart';

class MyApp extends StatelessWidget {
  final bool isAdminLoggedIn;
  final bool isUserLoggedIn;
  
  const MyApp({super.key, required this.isAdminLoggedIn, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali Grandsons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: kSurfaceColor,
          background: kBackgroundColor,
          error: kErrorColor,
        ),
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: kTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: kTextSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurfaceColor,
          foregroundColor: kPrimaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: kPrimaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreyLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: kTextSecondary),
          floatingLabelStyle: const TextStyle(color: kPrimaryColor),
        ),
        cardTheme: CardThemeData(
          color: kSurfaceColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: _getInitialScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login_user': (context) => const LoginUserPage(),
        '/login_admin': (context) => const LoginAdminPage(),
        '/signup_user': (context) => const SignupUserPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/user_dashboard': (context) => const UserDashboardPage(),
      },
    );
  }

  Widget _getInitialScreen() {
    if (isAdminLoggedIn) return const AdminDashboardPage();
    if (isUserLoggedIn) return const UserDashboardPage();
    return const HomePage();
  }
}
