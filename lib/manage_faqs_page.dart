import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_edit_faq_page.dart';

// ManageFAQsPage is an admin-only screen used to add, edit, or delete Frequently Asked Questions.
class ManageFAQsPage extends StatefulWidget {
  const ManageFAQsPage({super.key});

  @override
  State<ManageFAQsPage> createState() => _ManageFAQsPageState();
}

class _ManageFAQsPageState extends State<ManageFAQsPage> {
  // A list to store the FAQs fetched from the database.
  List<Map<String, dynamic>> _faqs = [];
  
  // Loading state to show a progress spinner while data is being loaded.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the existing FAQs as soon as the admin opens this page.
    _loadFAQs();
  }

  // Fetches all FAQs from the database.
  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
    });
    final db = DatabaseHelper.instance;
    var faqs = await db.getAllFAQs();
    
    // If there are no FAQs at all, auto-fill the list with default ones.
    if (faqs.isEmpty) {
      await db.seedFAQs();
      faqs = await db.getAllFAQs();
    }

    setState(() {
      _faqs = faqs;
      _isLoading = false;
    });
  }

  // Resets the FAQ list to the original set of questions provided by the app.
  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Defaults'),
        content: const Text('This will add the default FAQs again. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.seedFAQs();
      _loadFAQs(); // Refresh the list after restoring.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default FAQs restored')));
    }
  }

  // Permanently removes an FAQ from the database.
  Future<void> _deleteFAQ(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to remove this FAQ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteFAQ(id);
      _loadFAQs(); // Refresh the list after deleting.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage FAQs'),
        actions: [
          // Button to restore default questions.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restore Defaults',
            onPressed: _restoreDefaults,
          ),
          // Button to go to the page where a new FAQ can be added.
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditFAQPage()),
              ).then((_) => _loadFAQs()); // Refresh when returning from the add page.
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faqs.isEmpty
              ? const Center(child: Text('No FAQs found.'))
              : ListView.builder(
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(faq['question']),
                        subtitle: Text(faq['answer'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Button to edit an existing FAQ.
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddEditFAQPage(faq: faq)),
                                ).then((_) => _loadFAQs());
                              },
                            ),
                            // Button to delete an FAQ.
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFAQ(faq['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
