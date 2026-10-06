import 'dart:developer' as developer;
import '../config/api_config.dart';
import '../models/ai_chat_model.dart';
import 'api_service.dart';

class AiChatService {
  static Future<AiChatResponse> sendMessage({
    required String message,
    List<ChatMessage> history = const [],
  }) async {
    try {
      final historyPayload = history
          .where((m) => !m.isError)
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'content': m.text,
              })
          .toList();

      final body = {
        'message': message,
        'history': historyPayload,
      };

      final data = await ApiService.post(ApiConfig.aiChat, body: body);
      if (data is Map<String, dynamic>) {
        return AiChatResponse.fromJson(data);
      }

      throw Exception('Dữ liệu phản hồi từ máy chủ không hợp lệ');
    } catch (e) {
      developer.log('AI Chat error: $e');
      rethrow;
    }
  }
}
