import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicesService {
  static const String baseUrl = 'https://wealiens.com';

  Future<List<dynamic>> getCategoriesTree({String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/services/categories/tree?lang=$lang'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load categories tree');
    }
  }

  Future<List<dynamic>> getCategories({String lang = 'en', String status = 'active'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/services/categories?lang=$lang&status=$status'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> getCategoryDetails(int id, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/services/categories/$id?lang=$lang'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load category details');
    }
  }

  Future<Map<String, dynamic>?> getServiceDetailByCategory(int categoryId, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/services/categories/$categoryId/detail?lang=$lang'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>?;
    } else if (response.statusCode == 404) {
      return null; // Detail might not exist yet
    } else {
      throw Exception('Failed to load service details');
    }
  }

  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // If it's already a full URL but pointing to localhost, swap it
    if (url.contains('127.0.0.1:8000')) {
      return url.replaceAll('http://127.0.0.1:8000', baseUrl);
    }
    
    if (url.startsWith('http')) return url;

    // Ensure relative paths are handled correctly
    String normalized = url;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    return '$baseUrl$normalized';
  }
}
