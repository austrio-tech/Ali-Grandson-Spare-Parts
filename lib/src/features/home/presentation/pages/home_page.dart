import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (await SessionManager.isAdminLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (await SessionManager.isUserLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/user_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSurfaceColor, kBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'logo',
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: kSurfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset('lib/assets/Imgs/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'ALI GRANDSONS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const Text(
                  'Premium Spare Parts',
                  style: TextStyle(
                    fontSize: 16,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(flex: 3),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login_user'),
                  child: const Text('CUSTOMER LOGIN'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup_user'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: kPrimaryColor,
                  ),
                  child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login_admin'),
                  child: Text(
                    'ADMIN ACCESS',
                    style: TextStyle(
                      color: kSecondaryColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
