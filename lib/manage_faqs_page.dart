import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_edit_faq_page.dart';

class ManageFAQsPage extends StatefulWidget {
  const ManageFAQsPage({super.key});

  @override
  State<ManageFAQsPage> createState() => _ManageFAQsPageState();
}

class _ManageFAQsPageState extends State<ManageFAQsPage> {
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
    });
    final db = DatabaseHelper.instance;
    var faqs = await db.getAllFAQs();
    
    // Auto-seed if the list is empty
    if (faqs.isEmpty) {
      await db.seedFAQs();
      faqs = await db.getAllFAQs();
    }

    setState(() {
      _faqs = faqs;
      _isLoading = false;
    });
  }

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
      _loadFAQs();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default FAQs restored')));
    }
  }

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
      _loadFAQs();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage FAQs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restore Defaults',
            onPressed: _restoreDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditFAQPage()),
              ).then((_) => _loadFAQs());
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
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddEditFAQPage(faq: faq)),
                                ).then((_) => _loadFAQs());
                              },
                            ),
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
