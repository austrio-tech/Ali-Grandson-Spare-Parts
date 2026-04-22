import 'package:flutter/material.dart';
import 'database_helper.dart';

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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.faq == null ? 'FAQ added' : 'FAQ updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.faq == null ? 'Add FAQ' : 'Edit FAQ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a question' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Please enter an answer' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveFAQ,
                child: Text(widget.faq == null ? 'Add FAQ' : 'Update FAQ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
