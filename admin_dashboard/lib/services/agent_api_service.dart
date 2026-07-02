import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_response.dart';

class AgentApiService {
  final String baseUrl = 'http://localhost:8001/api';

  Stream<Map<String, dynamic>> sendMessageStream(String message) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/agentic-chat'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'message': message});

    try {
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to communicate. Status Code: ${response.statusCode}');
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        yield jsonDecode(chunk);
      }
    } catch (e) {
      throw Exception('Network error or connection refused: $e');
    }
  }
}

final agentApiServiceProvider = Provider<AgentApiService>((ref) {
  return AgentApiService();
});
