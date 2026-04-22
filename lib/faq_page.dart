import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'database_helper.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am the Ali Grandson Spare Parts assistant. How can I help you today? Tap the button below to see common questions.'
    }
  ];

  List<Map<String, dynamic>> _faqs = [];
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    final faqs = await DatabaseHelper.instance.getAllFAQs();
    setState(() {
      _faqs = faqs;
    });
  }

  void _handleQuestionClick(String question, String answer) {
    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _messages.add({'role': 'bot', 'text': answer});
    });
    // Scroll to bottom after adding messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFaqOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a Question',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No questions available yet.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _faqs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_faqs[index]['question']!),
                        onTap: () {
                          Navigator.pop(context);
                          _handleQuestionClick(
                            _faqs[index]['question']!,
                            _faqs[index]['answer']!,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs & Support'),
        centerTitle: true,
      ),
      body: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isBot = message['role'] == 'bot';
          return Align(
            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : maroon,
                borderRadius: BorderRadius.circular(15.0),
                border: isBot ? Border.all(color: silver) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(
                message['text']!,
                style: TextStyle(
                  color: isBot ? Colors.black87 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFaqOptions,
        backgroundColor: maroon,
        child: const Icon(Icons.question_answer, color: Colors.white),
      ),
    );
  }
}
