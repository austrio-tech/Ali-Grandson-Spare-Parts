import 'package:flutter/material.dart';
import 'database_helper.dart';

// AddEditFAQPage is a form used by admins to either create a new FAQ or change an existing one.
class AddEditFAQPage extends StatefulWidget {
  // If 'faq' is provided, we are in "Edit" mode. If it's null, we are in "Add" mode.
  final Map<String, dynamic>? faq;

  const AddEditFAQPage({super.key, this.faq});

  @override
  State<AddEditFAQPage> createState() => _AddEditFAQPageState();
}

class _AddEditFAQPageState extends State<AddEditFAQPage> {
  // GlobalKey is used to check if the text boxes are empty before saving.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to capture the question and answer text.
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If we are editing an existing FAQ, fill the text boxes with the current question and answer.
    if (widget.faq != null) {
      _questionController.text = widget.faq!['question'];
      _answerController.text = widget.faq!['answer'];
    }
  }

  // This function saves the data to the database.
  Future<void> _saveFAQ() async {
    // 1. Check if the user actually typed something in both boxes.
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> faqData = {
        'question': _questionController.text,
        'answer': _answerController.text,
      };

      if (widget.faq == null) {
        // 2a. If there's no existing FAQ, we insert a new record.
        await DatabaseHelper.instance.insertFAQ(faqData);
      } else {
        // 2b. If we are editing, we include the original ID so the database knows which one to update.
        faqData['id'] = widget.faq!['id'];
        await DatabaseHelper.instance.updateFAQ(faqData);
      }

      // 3. Go back to the previous screen and show a success message.
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
        // Dynamic title based on whether we are adding or editing.
        title: Text(widget.faq == null ? 'Add FAQ' : 'Edit FAQ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Input field for the Question.
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a question' : null,
              ),
              const SizedBox(height: 16),
              // Input field for the Answer. maxLines allows it to grow vertically for long answers.
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Please enter an answer' : null,
              ),
              const SizedBox(height: 32),
              // The button that triggers the save process.
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
