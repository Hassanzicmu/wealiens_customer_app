import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/customer_profile.dart';
import '../models/project.dart';
import '../models/ticket.dart';

class AuthService {
  static const String baseUrl = 'https://wealiens.com';
  final _storage = const FlutterSecureStorage();
  
  GoogleSignIn? __googleSignIn;
  GoogleSignIn get _googleSignIn => __googleSignIn ??= GoogleSignIn(
    clientId: '648999744722-s5aam4gcs1nhr0b01sunu3cm8chmatm3.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/customer/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': 'flutter',
      }),
    );

    print('LOGIN URL: $baseUrl/api/customer/login');
    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY SAMPLE: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['access_token']?.toString();
        final customer = data['customer'] as Map<String, dynamic>?;

        if (token != null && customer != null) {
          await _storage.write(key: 'access_token', value: token);
          await _storage.write(key: 'customer', value: jsonEncode(customer));
          return {'success': true, 'customer': customer};
        }
      }

      String errorMessage = 'Login failed';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        errorMessage = errors.values.first.first.toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }

      return {
        'success': false, 
        'message': errorMessage
      };
    } catch (e) {
      print('LOGIN PARSING ERROR: $e');
      print('FAILED BODY: ${response.body}');
      return {'success': false, 'message': 'Invalid response from server (Parse Error)'};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Sign in cancelled'};

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return {'success': false, 'message': 'Failed to obtain ID Token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/customer/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
          'device_name': 'flutter',
        }),
      );

      print('GOOGLE LOGIN STATUS: ${response.statusCode}');
      print('GOOGLE LOGIN BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['access_token']?.toString();
        final customer = data['customer'] as Map<String, dynamic>?;

        if (token != null && customer != null) {
          await _storage.write(key: 'access_token', value: token);
          await _storage.write(key: 'customer', value: jsonEncode(customer));
          return {'success': true, 'customer': customer};
        }
      }

      return {
        'success': false,
        'message': (data['message'] ?? 'Google Login failed').toString()
      };
    } catch (e) {
      print('GOOGLE LOGIN ERROR: $e');
      return {'success': false, 'message': 'An error occurred during Google Sign-in'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/customer/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'flutter',
      }),
    );

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER BODY: ${response.body}');

    try {
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == 'success') {
        final token = data['access_token']?.toString();
        final customer = data['customer'] as Map<String, dynamic>?;

        if (token != null && customer != null) {
          await _storage.write(key: 'access_token', value: token);
          await _storage.write(key: 'customer', value: jsonEncode(customer));
          return {'success': true, 'customer': customer};
        }
      }
      
      String errorMessage = 'Registration failed';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        errorMessage = errors.values.first.first.toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }
      
      return {
        'success': false, 
        'message': errorMessage
      };
    } catch (e) {
      print('PARSING ERROR: $e');
      return {'success': false, 'message': 'Invalid response from server'};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/api/customer/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'customer');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/customer/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('ME STATUS: ${response.statusCode}');
    print('ME BODY: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>?;
      } catch (e) {
        print('ME PARSING ERROR: $e');
      }
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Map<String, dynamic>?> getStoredCustomer() async {
    final customerStr = await _storage.read(key: 'customer');
    if (customerStr != null) {
      return jsonDecode(customerStr);
    }
    return null;
  }

  Future<CustomerProfile?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/customer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PROFILE STATUS: ${response.statusCode}');
      print('PROFILE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerProfile.fromJson(data);
      }
    } catch (e) {
      print('FETCH PROFILE ERROR: $e');
    }
    return null;
  }

  Future<List<Project>> getProjects() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/customer/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PROJECTS STATUS: ${response.statusCode}');
      print('PROJECTS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerProjectsResponse.fromJson(data).projects;
      } else {
        print('PROJECTS ERROR STATUS: ${response.statusCode}');
        print('PROJECTS ERROR BODY: ${response.body}');
      }
    } catch (e, stack) {
      print('FETCH PROJECTS ERROR: $e');
      print('STACK TRACE: $stack');
    }
    return [];
  }
  Future<bool> createProject({
    required String title,
    String? description,
    required List<int> servicesCategoryIds,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/customer/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'services_category_ids': servicesCategoryIds,
        }),
      );

      print('CREATE PROJECT STATUS: ${response.statusCode}');
      print('CREATE PROJECT BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('CREATE PROJECT ERROR: $e');
      return false;
    }
  }

  Future<PaginatedTickets?> getTickets({int page = 1}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/customer/tickets?page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaginatedTickets.fromJson(data);
      }
    } catch (e) {
      print('FETCH TICKETS ERROR: $e');
    }
    return null;
  }

  Future<Ticket?> getTicketDetails(int id) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/customer/tickets/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ticket.fromJson(data);
      }
    } catch (e) {
      print('FETCH TICKET DETAILS ERROR: $id - $e');
    }
    return null;
  }

  Future<bool> createTicket({
    required int projectId,
    required String title,
    required String description,
    File? attachment,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/customer/tickets');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..fields['customer_project_id'] = projectId.toString()
        ..fields['title'] = title
        ..fields['description'] = description;

      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('CREATE TICKET STATUS: ${response.statusCode}');
      print('CREATE TICKET BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('CREATE TICKET ERROR: $e');
      return false;
    }
  }

  Future<bool> replyToTicket({
    required int ticketId,
    required String replyText,
    File? attachment,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/customer/tickets/$ticketId/reply');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..fields['reply_text'] = replyText;

      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('REPLY TICKET STATUS: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('REPLY TICKET ERROR: $e');
      return false;
    }
  }

  Future<List<TicketReply>> getTicketComments(int ticketId) async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/customer/tickets/$ticketId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((x) => TicketReply.fromJson(x)).toList();
      }
    } catch (e) {
      print('GET TICKET COMMENTS ERROR: $e');
    }
    return [];
  }
}
