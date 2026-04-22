import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'database_helper.dart';
import 'admin_dashboard.dart';

// LoginAdminPage is a dedicated screen for store administrators to log in.
class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  // _formKey helps us track the state of the form (like checking if fields are empty).
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to get the text entered by the admin in the email and password boxes.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // This function handles the login process when the 'Login' button is pressed.
  void _login() async {
    // Validate the form to ensure all fields are filled correctly.
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;
      
      // Check the 'admins' table in our database for matching credentials.
      final admin = await DatabaseHelper.instance.getAdmin(email, password);

      if (admin != null) {
        // If an admin is found, remember that they are logged in using SharedPreferences.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('admin_logged_in', true);
        await prefs.setString('admin_email', email);

        if (!mounted) return;
        // Move to the Admin Dashboard screen. pushReplacement means they can't go back to the login screen.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        // If the email or password doesn't match, show an error message.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Circular logo at the top of the login form.
                const CircleAvatar(
                  radius: 80,
                  backgroundColor: maroon,
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Image(
                        image: AssetImage('lib/Imgs/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Input field for the admin email.
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Input field for the admin password. It hides the text being typed.
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // The button that triggers the _login function.
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
