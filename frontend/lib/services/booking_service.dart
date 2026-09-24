import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class BookingService {
  // ✅ CHECK AVAILABILITY (multi-size)
  static Future<Map<String, dynamic>?> checkAvailability(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/bookings/check"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("Availability Error ${response.statusCode}: ${response.body}");
      return {
        "IsAvailable": false,
        "Message": response.body.isNotEmpty
            ? response.body
            : "Availability check failed (HTTP ${response.statusCode}).",
      };
    } catch (e) {
      print("Availability Exception: $e");
      return {
        "IsAvailable": false,
        "Message": "Cannot reach server. Is the backend running?",
      };
    }
  }

  // ✅ CONFIRM BOOKING → { Success: bool, Message: String }
  static Future<Map<String, dynamic>> confirmBooking(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/bookings/confirm"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          "Success": true,
          "Message": body["Message"] ?? "Booking Confirmed",
        };
      }

      print("Confirm Booking Error ${response.statusCode}: ${response.body}");
      return {
        "Success": false,
        "Message": response.body.isNotEmpty
            ? response.body
            : "Booking failed (HTTP ${response.statusCode})",
      };
    } catch (e) {
      print("Confirm Booking Exception: $e");
      return {
        "Success": false,
        "Message": "Cannot reach server. Is the backend running?",
      };
    }
  }

  // ✅ CANCEL BOOKING
  static Future<Map<String, dynamic>?> cancelBooking(
    int userId,
    int bookingId,
  ) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/bookings/cancel"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"UserId": userId, "BookingId": bookingId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Cancel Error: ${response.body}");
      return null;
    }
  }

  // ✅ RESCHEDULE BOOKING
  static Future<Map<String, dynamic>?> rescheduleBooking(
    int userId,
    int bookingId,
    String startDate,
    String endDate,
  ) async {
    final response = await http.post(
      Uri.parse("${Config.baseUrl}/bookings/reschedule"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "UserId": userId,
        "BookingId": bookingId,
        "StartDate": startDate,
        "EndDate": endDate,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Reschedule Error: ${response.body}");
      return null;
    }
  }

  // ✅ GET CREDIT BALANCE
  static Future<double> getCredit(int userId) async {
    final response = await http.get(
      Uri.parse("${Config.baseUrl}/bookings/credit/$userId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data["CreditBalance"] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }
}
