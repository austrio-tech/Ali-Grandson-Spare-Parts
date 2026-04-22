import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'view_user_page.dart';

// ManageUsersPage is an administrative screen that lists all registered customers.
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // A list to hold the user records fetched from the database.
  List<Map<String, dynamic>> _users = [];
  
  // A flag to show a loading spinner while data is being retrieved.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the list of users as soon as the admin opens this page.
    _loadUsers();
  }

  // Gets all user accounts from the 'users' table in the database.
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    final users = await DatabaseHelper.instance.getUsers();
    setState(() {
      _users = users;
      _isLoading = false; // Hide the loading spinner once data is ready.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show spinner if loading.
          : _users.isEmpty
              ? const Center(child: Text('No users found.')) // Message if no users exist.
              : ListView.builder(
                  // Creates a scrolling list of users.
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        // Display user's name and email.
                        title: Text(user['name'] ?? 'No Name'),
                        subtitle: Text(user['email'] ?? 'No Email'),
                        onTap: () {
                          // Clicking a user goes to their detailed profile page.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewUserPage(user: user),
                            ),
                          ).then((_) => _loadUsers()); // Refresh the list when returning.
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
