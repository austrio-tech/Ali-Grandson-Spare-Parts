import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// ProfilePage allows users to view and update their personal information.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // GlobalKey is used to identify the form and check for validation errors.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to manage the text inside the input fields.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the user's current data when the page is opened.
    _loadUserProfile();
  }

  // Fetches user details from the database and fills the text fields.
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';

    if (username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(username);
      if (user != null) {
        setState(() {
          _username = username;
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          _passwordController.text = user['password'] ?? '';
        });
      }
    }
    setState(() {
      _isLoading = false; // Hide the loading spinner.
    });
  }

  // Saves the changes made by the user back to the database.
  Future<void> _updateProfile() async {
    // 1. Check if the inputs are valid (e.g., email has @, password is long enough).
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;

      // 2. Make sure the new email isn't already taken by someone else.
      final isEmailTaken = await DatabaseHelper.instance.isEmailTaken(email, _username);
      if (isEmailTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already registered by another user.')),
        );
        return;
      }

      // 3. Prepare the updated user data.
      final updatedUser = {
        'username': _username,
        'name': _nameController.text,
        'email': email,
        'phone': _phoneController.text,
        'password': _passwordController.text,
      };

      // 4. Update the record in the database.
      await DatabaseHelper.instance.updateUser(updatedUser);

      // 5. Update the locally saved email preference.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);

      // 6. Notify the user of success.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display the username (it cannot be changed).
                    Text(
                      'Username: $_username',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Input for Name.
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 15),
                    // Input for Email with pattern validation.
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // Input for Phone Number.
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: 15),
                    // Input for Password.
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter a password';
                        if (value.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    // Button to submit updates.
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
