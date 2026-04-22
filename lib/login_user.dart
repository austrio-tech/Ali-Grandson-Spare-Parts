import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'database_helper.dart';
import 'user_dashboard.dart';

// LoginUserPage is where customers sign into their accounts.
class LoginUserPage extends StatefulWidget {
  const LoginUserPage({super.key});

  @override
  State<LoginUserPage> createState() => _LoginUserPageState();
}

class _LoginUserPageState extends State<LoginUserPage> {
  // _formKey is used to identify the form and perform validation (checking if fields are empty).
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to capture the text typed into the email and password fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // This function is triggered when the user clicks the 'Login' button.
  void _login() async {
    // Check if the input fields are valid according to our rules.
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;
      
      // Check the database to see if a user with this email and password exists.
      final user = await DatabaseHelper.instance.getUser(email, password);

      if (user != null) {
        // If the user is found, save their login state so they don't have to log in again next time.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_logged_in', true);
        await prefs.setString('user_email', email);
        await prefs.setString('user_username', user['username']);

        // Navigate to the User Dashboard and remove the login screen from history.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserDashboard()),
        );
      } else {
        // If login fails, show a brief message at the bottom of the screen.
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
        title: const Text('User Login'),
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
                // Display the brand logo at the top.
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
                // Text input field for the email.
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
                // Text input field for the password (hides characters).
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
                // Button to submit the form.
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
