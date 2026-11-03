import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  const ApiService({this.baseUrl = 'http://localhost:8080/api'});

  final String baseUrl;

  Future<List<Map<String, dynamic>>> getMedicines({String query = ''}) async {
    final uri = Uri.parse('$baseUrl/medicines').replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Medicine request failed (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode != 200) throw Exception('Backend is unavailable');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
