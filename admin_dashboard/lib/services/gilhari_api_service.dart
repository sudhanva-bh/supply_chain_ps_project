import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GilhariApiService {
  // Now points to the FastAPI backend proxy
  static const String baseUrl = 'http://localhost:8001/api/gilhari';

  Future<String?> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_password');
  }

  Future<Map<String, String>> _getHeaders() async {
    final pass = await _getPassword();
    return {
      'Content-Type': 'application/json',
      if (pass != null) 'X-App-Password': pass,
    };
  }

  Future<List<dynamic>> getEntities(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching $endpoint: $e');
      rethrow;
    }
  }

  Future<bool> createEntity(String endpoint, Map<String, dynamic> data) async {
    final payload = {"entity": data};
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Create failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating $endpoint: $e');
      return false;
    }
  }

  Future<bool> updateEntity(String endpoint, Map<String, dynamic> data) async {
    final payload = {"entity": data};
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating $endpoint: $e');
      return false;
    }
  }

  Future<bool> deleteEntity(String endpoint, Map<String, dynamic> data) async {
    final payload = {"entity": data};
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl/$endpoint'));
      request.headers.addAll(await _getHeaders());
      request.body = json.encode(payload);

      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        return true;
      } else {
        final respBody = await response.stream.bytesToString();
        debugPrint('Delete failed: $respBody');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting $endpoint: $e');
      return false;
    }
  }
}

final gilhariApiService = GilhariApiService();

