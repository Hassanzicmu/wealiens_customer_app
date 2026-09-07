import 'dart:convert';
import 'package:http/http.dart' as http;

class ContactService {
  static const String baseUrl = 'https://wealiens.com';

  Future<Map<String, dynamic>> submitContactForm({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
    String countryCode = '+20',
    String countryShort = 'EG',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/contact'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'country_code': countryCode,
        'country_short': countryShort,
        'phone': phone,
        'subject': subject,
        'message': message,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to submit contact form');
    }
  }
}
