import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class RentalService {
  static Future<List<dynamic>> getCustomerRentals(int userId) async {
    final response = await http.get(
      Uri.parse("${Config.baseUrl}/rentals/user/$userId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getOwnerBookings(int ownerId) async {
    final response = await http.get(
      Uri.parse("${Config.baseUrl}/rentals/owner/$ownerId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> updateBookingStatus(int bookingId, int status) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/rentals/update-status"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"BookingId": bookingId, "Status": status}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> submitReview(
    int bookingId,
    int dressId,
    int rating,
  ) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/rentals/add-review"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "BookingId": bookingId,
        "DressId": dressId,
        "Rating": rating,
        "Feedback": null,
      }),
    );

    return response.statusCode == 200;
  }
}
