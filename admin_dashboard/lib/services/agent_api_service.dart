import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentApiService {
  final String baseUrl = 'http://localhost:8001/api';

  Future<String?> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_password');
  }

  Stream<Map<String, dynamic>> sendMessageStream(String message) async* {
    final pass = await _getPassword();
    final request = http.Request('POST', Uri.parse('$baseUrl/agentic-chat'));
    request.headers['Content-Type'] = 'application/json';
    if (pass != null) request.headers['X-App-Password'] = pass;
    request.body = jsonEncode({'message': message});

    try {
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to communicate. Status Code: ${response.statusCode}',
        );
      }

      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        yield jsonDecode(chunk);
      }
    } catch (e) {
      throw Exception('Network error or connection refused: $e');
    }
  }

  Future<Map<String, dynamic>> executeTool(
    String toolName,
    String argsJson,
  ) async {
    final pass = await _getPassword();
    final request = http.Request('POST', Uri.parse('$baseUrl/execute-tool'));
    request.headers['Content-Type'] = 'application/json';
    if (pass != null) request.headers['X-App-Password'] = pass;
    request.body = jsonEncode({'tool_name': toolName, 'args_json': argsJson});

    try {
      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to execute tool. Status Code: ${response.statusCode}, Body: $responseBody',
        );
      }

      return jsonDecode(responseBody);
    } catch (e) {
      throw Exception('Network error or connection refused: $e');
    }
  }
}

final agentApiServiceProvider = Provider<AgentApiService>((ref) {
  return AgentApiService();
});
