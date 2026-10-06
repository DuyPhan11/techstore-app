import 'product_model.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ProductModel> suggestedProducts;
  final List<String> quickReplies;
  final bool isError;
  final bool fromAi;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedProducts = const [],
    this.quickReplies = const [],
    this.isError = false,
    this.fromAi = false,
  });
}

class AiChatResponse {
  final String reply;
  final List<ProductModel> suggestedProducts;
  final List<String> quickReplies;
  final bool fromAi;

  AiChatResponse({
    required this.reply,
    this.suggestedProducts = const [],
    this.quickReplies = const [],
    this.fromAi = false,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    List<ProductModel> products = [];
    if (json['suggestedProducts'] != null && json['suggestedProducts'] is List) {
      products = (json['suggestedProducts'] as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<String> replies = [];
    if (json['quickReplies'] != null && json['quickReplies'] is List) {
      replies = (json['quickReplies'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return AiChatResponse(
      reply: json['reply']?.toString() ?? '',
      suggestedProducts: products,
      quickReplies: replies,
      fromAi: json['fromAi'] == true,
    );
  }
}
