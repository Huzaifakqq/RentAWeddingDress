import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthService {
  static const String baseUrl = Config.baseUrl;

  static Future<Map<String, dynamic>?> login(
    String contact,
    String password, {
    String role = "customer", // login screen mode: "customer" | "rider"
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Contact": contact,
        "Password": password,
        "Role": role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Surface the backend's message (e.g. "This is not a rider account")
      try {
        final errorData = jsonDecode(response.body);
        return {"Error": errorData["Message"] ?? "Login Failed"};
      } catch (_) {
        return null;
      }
    }
  }

  static Future<String?> register(
    String name,
    String contact,
    String password,
    String confirmPassword, {
    String role = "customer", // signup toggle: "customer" | "rider"
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Name": name,
        "Contact": contact,
        "Password": password,
        "ConfirmPassword": confirmPassword,
        "Role": role,
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
