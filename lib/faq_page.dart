import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'database_helper.dart';

// FAQPage provides a chat-like interface for users to find answers to common questions.
class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // A list to store the history of the conversation (bot greetings, user questions, and bot answers).
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am the Ali Grandson Spare Parts assistant. How can I help you today? Tap the button below to see common questions.'
    }
  ];

  // List to store the FAQs retrieved from the database.
  List<Map<String, dynamic>> _faqs = [];
  
  // Controller to handle automatic scrolling when new messages appear.
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load the questions from the database as soon as the page opens.
    _loadFAQs();
  }

  // Fetches all available FAQs from the database.
  Future<void> _loadFAQs() async {
    final faqs = await DatabaseHelper.instance.getAllFAQs();
    setState(() {
      _faqs = faqs;
    });
  }

  // This function runs when a user selects a question to ask.
  void _handleQuestionClick(String question, String answer) {
    setState(() {
      // Add the user's question to the chat list.
      _messages.add({'role': 'user', 'text': question});
      // Add the bot's pre-defined answer to the chat list.
      _messages.add({'role': 'bot', 'text': answer});
    });
    
    // Scroll to the bottom of the chat so the new message is visible.
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

  // Opens a pop-up menu from the bottom (BottomSheet) containing all FAQ questions.
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
            mainAxisSize: MainAxisSize.min, // Takes only as much space as needed.
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
                // Flexible allows the list to scroll if there are many questions.
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _faqs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_faqs[index]['question']!),
                        onTap: () {
                          Navigator.pop(context); // Close the menu.
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
      // Displays the conversation history as a list of "bubbles".
      body: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isBot = message['role'] == 'bot';
          return Align(
            // Bot messages on the left, user messages on the right.
            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : maroon, // Distinct colors for bot/user.
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
                maxWidth: MediaQuery.of(context).size.width * 0.75, // Message bubble width.
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
      // A floating button that opens the question list.
      floatingActionButton: FloatingActionButton(
        onPressed: _showFaqOptions,
        backgroundColor: maroon,
        child: const Icon(Icons.question_answer, color: Colors.white),
      ),
    );
  }
}
