import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/dress_model.dart';
import '../config.dart';
import '../models/dress_details_model.dart';

class DressService {
  static const String baseUrl = Config.baseUrl;

  // ✅ FILTER API
  static Future<List<DressModel>> filterDresses(
    Map<String, dynamic> filterData,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/dresses/filter"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(filterData),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => DressModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // ✅ GET CATEGORIES
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/dresses/categories"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // ✅ GET SUBCATEGORIES
  static Future<List<dynamic>> getSubCategories(int categoryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/dresses/categories/$categoryId/subcategories"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // ✅ GET SIZES
  static Future<List<dynamic>> getSizes() async {
    final response = await http.get(Uri.parse("$baseUrl/dresses/sizes"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<DressDetailsModel?> getDressDetails(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/dresses/$id"));

    if (response.statusCode == 200) {
      return DressDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  static Future<String?> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/dresses/upload-image"),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        final decoded = jsonDecode(responseData);
        return decoded["ImagePath"];
      } else {
        return null;
      }
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  static Future<bool> createDress(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/dresses/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Create Dress Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create Dress Exception: $e");
      return false;
    }
  }

  // ✅ CHECK AVAILABILITY
  static Future<Map<String, dynamic>?> checkAvailability(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/bookings/check"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ✅ GET USER ADDRESSES
  static Future<List<dynamic>> getUserAddresses(int userId) async {
    final response = await http.get(
      Uri.parse("${Config.baseUrl}/users/$userId/addresses"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ✅ ADD NEW ADDRESS
  static Future<bool> addAddress(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/users/add-address"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print("Add Address Status: ${response.statusCode}");
      print("Add Address Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Add Address Exception: $e");
      return false;
    }
  }

  static Future<List<ReviewModel>> getAllReviews(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/dresses/$id/reviews"));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ReviewModel.fromJson(e)).toList();
    }
    return [];
  }
}
