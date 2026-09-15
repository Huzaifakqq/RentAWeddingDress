import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class BookingService {
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
    } else {
      print("Availability Error: ${response.body}");
      return null;
    }
  }

  // ✅ CONFIRM BOOKING
  static Future<bool> confirmBooking(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/bookings/confirm"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Confirm Booking Error: ${response.body}");
      return false;
    }
  }
}
