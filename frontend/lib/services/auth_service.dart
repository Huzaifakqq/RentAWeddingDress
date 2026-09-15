import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthService {
  static const String baseUrl = Config.baseUrl;

  static Future<Map<String, dynamic>?> login(
    String contact,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Contact": contact, "Password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<String?> register(
    String name,
    String contact,
    String password,
    String confirmPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Name": name,
        "Contact": contact,
        "Password": password,
        "ConfirmPassword": confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return "success";
    } else {
      final errorData = jsonDecode(response.body);
      return errorData["Message"] ?? "Registration Failed";
    }
  }
}
