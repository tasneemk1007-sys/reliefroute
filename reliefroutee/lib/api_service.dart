import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  const ApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api',
    ),
  });

  final String baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
  final headers = <String, String>{'Accept': 'application/json'};

  if (json) headers['Content-Type'] = 'application/json';

  final user = FirebaseAuth.instance.currentUser;

  debugPrint('[ReliefRoute] Firebase user signed in: ${user != null}');

  final token = await user?.getIdToken();

  debugPrint(
    '[ReliefRoute] Firebase ID token obtained: ${token != null && token.isNotEmpty}',
  );

  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }

  return headers;
}

  Future<List<Map<String, dynamic>>> getMedicines({String query = ''}) async {
    final uri = Uri.parse('$baseUrl/medications').replace(
      queryParameters: query
          .trim()
          .isEmpty ? null : {'q': query.trim()},
    );
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 5));

    debugPrint('[Medicines] URL: $uri');
    debugPrint('[Medicines] Status: ${response.statusCode}');

    final data = jsonDecode(response.body) as List<dynamic>;

    for (final item in data) {
      debugPrint(
        '[Medicine Check] '
            'Name: ${item['name']}, '
            'Active: ${item['active']}, '
            'Stock: ${item['stock_quantity']}, '
            'Prescription: ${item['prescription_required']}, '
            'Demo: ${item['demo_record']}',
      );
    }

    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(
      Uri.parse('$baseUrl/firebase-check'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('Backend is unavailable');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(json: true),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decodeObject(response, 'Login failed');
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(json: true),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _decodeObject(response, 'Registration failed');
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/directory/doctors'),
      headers: await _headers(),
    );

    return _decodeList(response, 'Could not load doctors');
  }

  Future<List<Map<String, dynamic>>> getPharmacies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/directory/pharmacies'),
      headers: await _headers(),
    );

    return _decodeList(response, 'Could not load pharmacies');
  }

  Future<List<dynamic>> getReminders() => _getList('/refill_reminders');
  Future<List<dynamic>> getOrders() => _getList('/orders');
  Future<List<dynamic>> getPrescriptions() => _getList('/prescriptions');

  Future<List<Map<String, dynamic>>> getCareReminders() async => _decodeList(
    await http.get(
      Uri.parse('$baseUrl/care/reminders'),
      headers: await _headers(),
    ),
    'Could not load reminders',
  );

  Future<Map<String, dynamic>> createCareReminder({
    required String medicine,
    required String time,
    required String frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/care/reminders'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'medicine': medicine,
        'time': time,
        'frequency': frequency,
      }),
    );
    return _decodeObject(response, 'Could not save reminder');
  }

  Future<List<Map<String, dynamic>>> getCarePrescriptions() async =>
      _decodeList(
        await http.get(
          Uri.parse('$baseUrl/care/prescriptions'),
          headers: await _headers(),
        ),
        'Could not load prescriptions',
      );

  Future<Map<String, dynamic>> createCarePrescription(String filePath) async {
    final response = await http.post(
      Uri.parse('$baseUrl/care/prescriptions'),
      headers: await _headers(json: true),
      body: jsonEncode({'filePath': filePath}),
    );
    return _decodeObject(response, 'Could not save prescription');
  }

  Future<List<Map<String, dynamic>>> getAddresses() async => _decodeList(
    await http.get(
      Uri.parse('$baseUrl/care/addresses'),
      headers: await _headers(),
    ),
    'Could not load addresses',
  );

  Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> address,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/care/addresses'),
      headers: await _headers(json: true),
      body: jsonEncode(address),
    );
    return _decodeObject(response, 'Could not save address');
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    if (response.statusCode != 200) throw Exception('Request failed');
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> addReminder({
    required String medicine,
    required String time,
    required String frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/refill_reminders'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'medicine': medicine,
        'time': time,
        'frequency': frequency,
      }),
    );
    if (response.statusCode != 201) throw Exception('Could not save reminder');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitPrescription(String fileName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: await _headers(json: true),
      body: jsonEncode({'fileName': fileName}),
    );
    if (response.statusCode != 201) {
      throw Exception('Could not submit prescription');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getOrdersForUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user/${Uri.encodeComponent(userId)}'),
      headers: await _headers(),
    );
    return _decodeList(response, 'Could not load orders');
  }
  Future<Map<String, dynamic>> quoteOrder({
    required String userId,
    required String address,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/quote'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'user_id': userId,
        'address': address,
        'items': items,
      }),
    );

    return _decodeObject(response, 'Could not calculate order total');
  }

  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String address,
    required List<Map<String, dynamic>> items,
    required double expectedTotal,
    String pharmacyId = '',
    String prescriptionId = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/place'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'user_id': userId,
        'address': address,
        'pharmacy_id': pharmacyId,
        'prescription_id': prescriptionId,
        'items': items,
        'expected_total': expectedTotal,
      }),
    );

    return _decodeObject(response, 'Could not place the order');
  }

  Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/tracking'),
      headers: await _headers(),
    );
    return _decodeObject(response, 'Could not load order tracking');
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final response = await http.get(Uri.parse('$baseUrl/$collection'), headers: await _headers());
    return _decodeList(response, 'Could not load $collection');
  }

  Future<Map<String, dynamic>> createCollectionItem(
    String collection,
    Map<String, dynamic> value,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$collection'),
      headers: await _headers(json: true),
      body: jsonEncode(value),
    );
    return _decodeObject(response, 'Could not save $collection');
  }

  List<Map<String, dynamic>> _decodeList(
    http.Response response,
    String message,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$message (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _decodeObject(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$message (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
