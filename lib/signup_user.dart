import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_user.dart';

// SignupUserPage allows new customers to create an account.
class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
  // GlobalKey is used to identify and validate the entire form.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to capture the data entered by the user in each text box.
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  // This function is called when the 'Signup' button is pressed.
  void _signup() async {
    // 1. Validate the form: checks if required fields are filled and follow rules (like email format).
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final email = _emailController.text;

      // 2. Check if the username is already being used by someone else.
      final isUsernameTaken = await DatabaseHelper.instance.isUsernameTaken(username);
      if (isUsernameTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken. Please choose another.')),
        );
        return; // Stop the signup process if taken.
      }

      // 3. Check if the email is already registered.
      final isEmailTaken = await DatabaseHelper.instance.isEmailTaken(email);
      if (isEmailTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already registered. Please use another email.')),
        );
        return; // Stop the signup process if registered.
      }

      // 4. Create a Map (a set of key-value pairs) representing the new user.
      final user = {
        'username': username,
        'name': _nameController.text,
        'email': email,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'dob': _dobController.text,
      };
      
      // 5. Save the new user to the database.
      final id = await DatabaseHelper.instance.insertUser(user);

      if (id != 0) {
        // Success: Show a message and send the user to the Login page.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup Successful! Please login.')),
        );
        Navigator.pushReplacementNamed(context, '/login_user');
      } else {
        // Failure: Show an error message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during signup. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Signup'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Associate the form with our global key.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Username field with validation.
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Full Name field (optional).
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 20),
                // Email field with pattern matching (regex) to ensure it's a valid email format.
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Phone Number field.
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password field.
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  obscureText: true, // Hides the password.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Date of Birth field with a calendar picker.
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  readOnly: true, // User cannot type here; they must use the picker.
                  onTap: () async {
                    // Opens the system date picker.
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        // Format the date (YYYY-MM-DD) and show it in the text field.
                        _dobController.text = picked.toString().split(' ')[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 30),
                // The signup button.
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text('Signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
