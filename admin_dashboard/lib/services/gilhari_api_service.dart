import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GilhariApiService {
  static const String baseUrl = 'http://127.0.0.1/gilhari/v1';

  Future<List<dynamic>> getEntities(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
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
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
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
      request.headers.addAll({'Content-Type': 'application/json'});
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
