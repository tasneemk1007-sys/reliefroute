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

  Future<List<dynamic>> getReminders() => _getList('/reminders');
  Future<List<dynamic>> getOrders() => _getList('/orders');
  Future<List<dynamic>> getPrescriptions() => _getList('/prescriptions');

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) throw Exception('Request failed');
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> addReminder({
    required String medicine,
    required String time,
    required String frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'medicine': medicine, 'time': time, 'frequency': frequency}),
    );
    if (response.statusCode != 201) throw Exception('Could not save reminder');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitPrescription(String fileName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fileName': fileName}),
    );
    if (response.statusCode != 201) throw Exception('Could not submit prescription');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
