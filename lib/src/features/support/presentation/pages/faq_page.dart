import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am the Ali Grandson assistant. How can I help you today? Tap the button below to see common questions.'
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showFaqOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Help Center',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kSecondaryColor),
              ),
              const SizedBox(height: 16),
              if (_faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No common questions found.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _faqs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: kGreyLight),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_faqs[index]['question']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreyMedium),
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
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('SUPPORT CENTER'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(20.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isBot = message['role'] == 'bot';
          return _buildChatBubble(message['text']!, isBot);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFaqOptions,
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.question_answer_rounded, color: Colors.white),
        label: const Text('ASK A QUESTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isBot ? kSurfaceColor : kPrimaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 4 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? kSecondaryColor : Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
