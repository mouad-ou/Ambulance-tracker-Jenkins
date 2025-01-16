import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? category;
  final int? emergencyLevel;

  Message(
    this.text, 
    this.isUser, {
    this.category,
    this.emergencyLevel,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromResponse(ChatResponse response) {
    String category = '';
    if (response.categories != null) {
      category = response.categories!.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(', ');
    }
    return Message(
      response.response,
      false,
      category: category.isNotEmpty ? category : null,
      emergencyLevel: response.emergencyLevel,
    );
  }
}

class ChatResponse {
  final String response;
  final int? emergencyLevel;
  final Map<String, bool>? categories;

  const ChatResponse({
    required this.response,
    this.emergencyLevel,
    this.categories,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String,
      emergencyLevel: json['emergency_level'] as int?,
      categories: json['categories'] != null 
          ? Map<String, bool>.from(json['categories'] as Map)
          : null,
    );
  }

  bool get isEmergency => emergencyLevel != null && emergencyLevel! >= 3;
  
  String? get primaryCategory {
    if (categories == null || categories!.isEmpty) return null;
    final activeCategories = categories!.entries.where((e) => e.value);
    return activeCategories.isNotEmpty ? activeCategories.first.key : null;
  }
}