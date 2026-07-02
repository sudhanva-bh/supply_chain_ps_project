import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_response.dart';

class AgentApiService {
  final String baseUrl = 'http://localhost:8000/api';

  Future<AgentResponse> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agentic-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return AgentResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to communicate with AI Backend. Status Code: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      throw Exception('Network error or connection refused: $e');
    }
  }
}

final agentApiServiceProvider = Provider<AgentApiService>((ref) {
  return AgentApiService();
});
