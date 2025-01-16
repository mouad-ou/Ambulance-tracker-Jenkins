import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/chat_models.dart';

class AIService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '';
  static const int connectionTimeout = 10;
  static const int aiServiceTimeout = 90;
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Check internet connectivity
  Future<bool> checkConnectivity() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }
      return true;
    } catch (e) {
      print('Connectivity error: $e');
      return false;
    }
  }

  // Check if AI service is available
  Future<bool> checkAIServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),  // No /api/v1 as it's not in FastAPI code
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: connectionTimeout));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool healthy = data['status'] == 'healthy' && data['models_loaded'] == true;
        if (!healthy) {
          print('AI Service unhealthy: ${response.body}');
        }
        return healthy;
      }
      print('AI Service check failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error checking AI service: $e');
      return false;
    }
  }

  // Initialize speech recognition
  Future<bool> initializeSpeech() async {
    if (!_isListening) {
      try {
        bool available = await _speechToText.initialize(
          onError: (error) => print('Speech recognition error: $error'),
          onStatus: (status) => print('Speech recognition status: $status'),
        );
        return available;
      } catch (e) {
        print('Speech initialization error: $e');
        return false;
      }
    }
    return false;
  }

  // Start listening for speech input
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onListeningComplete,
    Function(String)? onError,
  }) async {
    if (!_isListening) {
      bool available = await initializeSpeech();
      if (available) {
        _isListening = true;
        try {
          await _speechToText.listen(
            onResult: (result) {
              if (result.finalResult) {
                onResult(result.recognizedWords);
                onListeningComplete();
              }
            },
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: true,
          );
        } catch (e) {
          _isListening = false;
          onError?.call(e.toString());
          print('Speech listening error: $e');
        }
      } else {
        onError?.call('Speech recognition not available');
      }
    }
  }

  // Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } finally {
        _isListening = false;
      }
    }
  }

  bool get isListening => _isListening;

  // Check for availability of internet and AI service
  Future<void> _checkAvailability() async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection available');
    }
    if (!await checkAIServiceAvailable()) {
      throw Exception('AI service is currently unavailable');
    }
  }

  // Get response from AI service (GPT-Neo model)
  Future<ChatResponse?> getResponse(String query, List<Message> conversationHistory) async {
    try {
      await _checkAvailability();
      
      final response = await http.post(
        Uri.parse('$baseUrl/virtual-assistant'),  // Using FastAPI endpoint for virtual assistant
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text': query,
          'conversation_history': conversationHistory.map((m) => m.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: aiServiceTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);  // Parse the response as per your data model
      } else {
        throw HttpException(
          'Failed to get response: ${response.statusCode} - ${response.body}'
        );
      }
    } on TimeoutException {
      print('Request timed out');
      return null;
    } catch (e) {
      print('Error getting AI response: $e');
      return null;
    }
  }

  // Function for voice commands, uses the getResponse function
  Future<ChatResponse?> processVoiceCommand(String text) async {
    final message = Message(text, true);  // User is the one sending voice command
    return getResponse(
      text, 
      [message]
    );
  }
}
