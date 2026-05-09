import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
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
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    var faqs = await db.getAllFAQs();
    
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will reset the FAQ list to the original factory questions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, minimumSize: const Size(100, 40)),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.seedFAQs();
      _loadFAQs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default FAQs restored'), backgroundColor: kSuccessColor));
    }
  }

  Future<void> _deleteFAQ(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete FAQ', style: TextStyle(fontWeight: FontWeight.bold, color: kErrorColor)),
        content: const Text('Are you sure you want to remove this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor, minimumSize: const Size(100, 40)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteFAQ(id);
      _loadFAQs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ deleted'), backgroundColor: kSecondaryColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('MANAGE FAQS'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: kSecondaryColor),
            tooltip: 'Restore Defaults',
            onPressed: _restoreDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditFAQPage()),
              ).then((_) => _loadFAQs());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faqs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) => _buildFAQCard(_faqs[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded, size: 80, color: kGreyMedium.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No FAQs found', style: TextStyle(color: kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kGreyLight)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          faq['question'],
          style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                Text(
                  faq['answer'],
                  style: const TextStyle(color: kTextSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditFAQPage(faq: faq)),
                        ).then((_) => _loadFAQs());
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('EDIT'),
                      style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteFAQ(faq['id']),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('DELETE'),
                      style: TextButton.styleFrom(foregroundColor: kErrorColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
