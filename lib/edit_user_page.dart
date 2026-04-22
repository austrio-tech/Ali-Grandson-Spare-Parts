import 'package:flutter/material.dart';
import 'database_helper.dart';

// EditUserPage is used by the administrator to modify a customer's details.
class EditUserPage extends StatefulWidget {
  // The 'user' variable holds the current information of the customer being edited.
  final Map<String, dynamic> user;

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  // _formKey helps us check if the information entered in the text boxes is correct.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to manage the text being edited in each input field.
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the text fields with the customer's existing data from the database.
    _usernameController.text = widget.user['username'] ?? '';
    _nameController.text = widget.user['name'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
    _phoneController.text = widget.user['phone'] ?? '';
    _dobController.text = widget.user['dob'] ?? '';
  }

  // This function is triggered when the admin clicks 'Update Details'.
  Future<void> _updateUser() async {
    // 1. Ensure all mandatory fields are filled out.
    if (_formKey.currentState!.validate()) {
      // 2. Collect the modified data into a Map.
      final updatedUser = {
        'username': _usernameController.text, // Username stays the same as it's the ID.
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
      };
      
      // 3. Save the updated information to the database.
      await DatabaseHelper.instance.updateUser(updatedUser);
      
      // 4. Close the edit page and go back.
      Navigator.pop(context); // Closes this page.
      Navigator.pop(context); // Closes the view page to trigger a refresh on the list.
      
      // 5. Show a success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Username is read-only because it identifies the account in the database.
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                readOnly: true,
              ),
              const SizedBox(height: 15),
              // Input for Customer Name.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 15),
              // Input for Customer Email.
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 15),
              // Input for Customer Phone Number.
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 15),
              // Input for Date of Birth with a calendar picker.
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                readOnly: true, // Prevents typing; must use the picker.
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _dobController.text = picked.toString().split(' ')[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
              // The button to save changes.
              ElevatedButton(
                onPressed: _updateUser,
                child: const Text('Update Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
