import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

class AddEditFAQPage extends StatefulWidget {
  final Map<String, dynamic>? faq;

  const AddEditFAQPage({super.key, this.faq});

  @override
  State<AddEditFAQPage> createState() => _AddEditFAQPageState();
}

class _AddEditFAQPageState extends State<AddEditFAQPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.faq != null) {
      _questionController.text = widget.faq!['question'];
      _answerController.text = widget.faq!['answer'];
    }
  }

  Future<void> _saveFAQ() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> faqData = {
        'question': _questionController.text,
        'answer': _answerController.text,
      };

      if (widget.faq == null) {
        await DatabaseHelper.instance.insertFAQ(faqData);
      } else {
        faqData['id'] = widget.faq!['id'];
        await DatabaseHelper.instance.updateFAQ(faqData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.faq == null ? 'New FAQ published' : 'FAQ updated'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.faq != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'EDIT FAQ' : 'ADD NEW FAQ'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isEdit),
              const SizedBox(height: 32),
              _buildFormContainer(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveFAQ,
                style: ElevatedButton.styleFrom(
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  elevation: 8,
                ),
                child: Text(isEdit ? 'SAVE CHANGES' : 'PUBLISH FAQ'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: AppColors.grey400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: AppColors.grey700,
                ),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isEdit ? Icons.edit_note_rounded : Icons.add_comment_rounded, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          isEdit ? 'Modify Support Content' : 'Help Your Customers',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        const Text(
          'Provide clear answers to common questions to improve user experience.',
          style: TextStyle(color: AppColors.grey600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Customer Question'),
          TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              hintText: 'e.g. How do I track my order?',
              prefixIcon: Icon(Icons.help_outline_rounded, size: 20),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Question is required' : null,
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Detailed Answer'),
          TextFormField(
            controller: _answerController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Provide a helpful response...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 110),
                child: Icon(Icons.description_outlined, size: 20),
              ),
              alignLabelWithHint: true,
            ),
            validator: (value) => value == null || value.isEmpty ? 'Answer is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 0.5),
      ),
    );
  }
}
