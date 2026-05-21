import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class WeatherChatScreen extends StatefulWidget {

  final String currentCity;
  final String currentTemperature;
  final String currentCondition;

  const WeatherChatScreen({
    super.key,
    required this.currentCity,
    required this.currentTemperature,
    required this.currentCondition,
  });

  @override
  State<WeatherChatScreen> createState() => _WeatherChatScreenState();
}

class _WeatherChatScreenState extends State<WeatherChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: 'AIzaSyBaXlJeQcPx-hR4K0RuUHuXUi-WUvSHS3g', // EYO DOUBLE CHECK THIS BRUH


      systemInstruction: Content.system(
          'You are BlueMoon AI, a friendly and witty weather chatbot assistant inside the BlueMoonWeathers app. '
              'CRITICAL LIVE CONTEXT: The user is currently viewing the weather dashboard for "${widget.currentCity}". '
              'The real-time temperature right now is ${widget.currentTemperature} and the climate is explicitly ${widget.currentCondition}. '
              'Use this specific live dashboard info to personalize your replies, recommend appropriate clothing, or suggest specific activities. Keep your answers light, natural, and fun!'
      ),
    );

    _chat = _model.startChat();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));

      setState(() {
        _messages.add({'sender': 'ai', 'text': response.text ?? 'Sorry, I couldn\'t think of anything to say.'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': 'System Error: $e'});
        _isLoading = false;
      });
    }
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueMoon AI Assistant'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[400] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about the weather, outfits...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}