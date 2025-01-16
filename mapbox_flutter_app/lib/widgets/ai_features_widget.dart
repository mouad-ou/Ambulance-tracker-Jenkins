import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../services/ai_service.dart';

// Define a consistent color palette for the medical chatbot
class MedicalChatColors {
  // Primary colors
  static const Color primary = Color(0xFF4A90E2);      // Soft Professional Blue
  static const Color secondary = Color(0xFF4ECDC4);    // Calming Teal
  static const Color background = Color(0xFFF5F5F5);   // Light Gray Background
  
  // Semantic colors
  static const Color userMessageBackground = Color(0xFFE6F2FF);  // Light Blue
  static const Color assistantMessageBackground = Color(0xFFF0F0F0);  // Light Gray
  static const Color emergencyBackground = Color(0xFFFFE6E6);  // Light Red
  
  // Text colors
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF666666);
  
  // Accent and status colors
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF4CAF50);
}

class AIFeaturesWidget extends StatefulWidget {
  const AIFeaturesWidget({Key? key}) : super(key: key);

  @override
  _AIFeaturesWidgetState createState() => _AIFeaturesWidgetState();
}

class _AIFeaturesWidgetState extends State<AIFeaturesWidget> {
  final AIService _aiService = AIService();
  final TextEditingController _queryController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isListening = false;
  bool _isLoading = false;
  String? _error;
  bool _showPrompts = true;  

  final List<Map<String, dynamic>> _promptCategories = [
  {
    'icon': '🩺',
    'label': 'Symptoms',
    'prompts': [
      'I have a persistent cough and body aches. Could this be flu or just a cold?',
      'I\'m experiencing sharp chest pain when breathing. Should I be worried?',
      'My joints are swollen and painful. What conditions might cause these symptoms?'
    ]
  },
  {
    'icon': '🏥',
    'label': 'Emergency',
    'prompts': [
      'My elderly parent seems confused, has drooping on one side of the face, and slurred speech. Could this be a stroke?',
      'My child has broken out in hives and is having difficulty breathing after eating nuts. What are the steps?',
      'I\'m having intense chest pain that radiates to my left arm. When exactly should I call 911?'
    ]
  },
  {
    'icon': '💊',
    'label': 'Medications',
    'prompts': [
      'I\'m taking blood pressure medication and an antidepressant. How can I check for potential drug interactions?',
      'Can you list the most common side effects of antibiotics I should be aware of?',
      'What are the best times of day to take different types of medications?'
    ]
  },
  {
    'icon': '🌡️',
    'label': 'Common Issues',
    'prompts': [
      'I have a fever of 101°F. What home remedies can help reduce my temperature safely?',
      'My blood pressure readings have been consistently high. What lifestyle changes can help manage this?',
      'I\'m experiencing severe seasonal allergy symptoms. What are the most effective treatment options?'
    ]
  },
  {
    'icon': '👶',
    'label': 'Children',
    'prompts': [
      'What vaccinations does my newborn need in the first year of life?',
      'My child has developed a red, itchy rash. Could this be a common childhood condition?',
      'When is a child\'s fever considered dangerous and requires medical attention?'
    ]
  }
];
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(Message(
        "Hello! I'm your medical assistant. How can I help you today?",
        false,
      ));
    });
  }

  Future<void> _initializeSpeech() async {
    await _aiService.initializeSpeech();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _showPrompts = false;
      });

      await _aiService.startListening(
        onResult: (text) async {
          setState(() {
            _queryController.text = text;
            _messages.add(Message(text, true));
            _isLoading = true;
          });
          _scrollToBottom();

          final response = await _aiService.getResponse(text, _messages);
          if (response != null) {
            setState(() {
              _messages.add(Message.fromResponse(response));
              _isLoading = false;
            });
            _scrollToBottom();
            
            if (response.isEmergency) {
              _showEmergencyAlert();
            }
          }
        },
        onListeningComplete: () {
          setState(() {
            _isListening = false;
          });
        },
        onError: (error) {
          setState(() {
            _error = error;
          });
        },
      );
    } else {
      await _aiService.stopListening();
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _sendMessage({String? promptText}) async {
    final String text = promptText ?? _queryController.text;
    if (text.isEmpty) return;

    _queryController.clear();
    setState(() {
      _messages.add(Message(text, true));
      _isLoading = true;
      _error = null;
      _showPrompts = false;
    });
    _scrollToBottom();

    final response = await _aiService.getResponse(text, _messages);
    if (response != null) {
      setState(() {
        _messages.add(Message.fromResponse(response));
        _isLoading = false;
      });
      _scrollToBottom();

      if (response.isEmergency) {
        _showEmergencyAlert();
      }
    } else {
      setState(() {
        _error = "Failed to get response from the medical assistant";
        _isLoading = false;
      });
    }
  }

  void _showEmergencyAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: MedicalChatColors.emergencyBackground,
        title: Text(
          '⚠️ Emergency Medical Situation',
          style: TextStyle(
            color: MedicalChatColors.emergencyRed, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          'This appears to be a medical emergency. Please call emergency services immediately.',
          style: TextStyle(
            fontSize: 16, 
            color: MedicalChatColors.primaryText
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Call Emergency'),
            onPressed: () {
              // TODO: Implement emergency call functionality
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: MedicalChatColors.emergencyRed,
            ),
          ),
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    Color bubbleColor = message.isUser 
        ? MedicalChatColors.userMessageBackground
        : message.emergencyLevel != null && message.emergencyLevel! >= 3
            ? MedicalChatColors.emergencyBackground
            : MedicalChatColors.assistantMessageBackground;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 16, 
                color: MedicalChatColors.primaryText
              ),
            ),
            if (message.category != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Category: ${message.category}',
                  style: TextStyle(
                    fontSize: 12,
                    color: MedicalChatColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: MedicalChatColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptsPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showPrompts ? 300 : 0,
      child: SingleChildScrollView(
        child: Container(
          color: MedicalChatColors.background,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: _promptCategories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          category['icon'] as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['label'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MedicalChatColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (category['prompts'] as List<String>).map((prompt) {
                      return InkWell(
                        onTap: () => _sendMessage(promptText: prompt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: MedicalChatColors.userMessageBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: MedicalChatColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            prompt,
                            style: TextStyle(
                              color: MedicalChatColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPromptsPanel(),
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: MedicalChatColors.primary,
                      )
                    ),
                  );
                }
              },
            ),
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: MedicalChatColors.emergencyBackground,
            child: Text(
              _error!,
              style: TextStyle(color: MedicalChatColors.emergencyRed),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _toggleListening,
                  color: _isListening ? MedicalChatColors.emergencyRed : MedicalChatColors.secondaryText,
                ),
                IconButton(
                  icon: Icon(_showPrompts ? Icons.close : Icons.add),
                  onPressed: () {
                    setState(() {
                      _showPrompts = !_showPrompts;
                    });
                  },
                  color: _showPrompts ? MedicalChatColors.emergencyRed : MedicalChatColors.secondaryText,
                ),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Type your medical question...',
                      hintStyle: TextStyle(color: MedicalChatColors.secondaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: MedicalChatColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                  color: MedicalChatColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
    void dispose() {
      _queryController.dispose();
      _scrollController.dispose();
      super.dispose();
    }
}