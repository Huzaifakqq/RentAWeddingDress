import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

// ✅ RIDER API — available orders, my deliveries, accept, status actions
class RiderService {
  static const String baseUrl = Config.baseUrl;

  // Pull backend error text out of Web API's response body
  static String _errorMessage(http.Response response, String fallback) {
    if (response.body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded["Message"] != null) {
        return decoded["Message"].toString();
      }
    } catch (_) {}
    return response.body;
  }

  // ✅ GET available orders near the rider
  // → { "Success": true, "Orders": [ ... ] }
  static Future<Map<String, dynamic>> getAvailable({
    required double lat,
    required double lng,
    double radiusKm = 25,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/bookings/rider/available"
          "?lat=$lat&lng=$lng&radiusKm=$radiusKm",
        ),
      );

      if (response.statusCode == 200) {
        return {"Success": true, "Orders": jsonDecode(response.body)};
      }

      return {
        "Success": false,
        "Message": _errorMessage(response, "Could not load orders"),
      };
    } catch (e) {
      print("Rider available Exception: $e");
      return {"Success": false, "Message": "Cannot reach server."};
    }
  }

  // ✅ GET orders assigned to this rider
  // → { "Success": true, "Orders": [ ... ] }
  static Future<Map<String, dynamic>> getMyDeliveries(
    int riderId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/rider/my/$riderId"),
      );

      if (response.statusCode == 200) {
        return {"Success": true, "Orders": jsonDecode(response.body)};
      }

      return {
        "Success": false,
        "Message": _errorMessage(response, "Could not load deliveries"),
      };
    } catch (e) {
      print("Rider my deliveries Exception: $e");
      return {"Success": false, "Message": "Cannot reach server."};
    }
  }

  // ✅ POST accept an available order (assigns it to this rider)
  // → { "Success": bool, "Message": String }
  static Future<Map<String, dynamic>> accept(
    int bookingId,
    int riderId,
  ) async {
    return _post("rider/accept", {
      "BookingId": bookingId,
      "RiderId": riderId,
    });
  }

  // ✅ POST status action: "picked" (1→4) or "delivered" (4→5)
  // → { "Success": bool, "Message": String }
  static Future<Map<String, dynamic>> updateAction(
    int bookingId,
    int riderId,
    String action,
  ) async {
    return _post("rider/action", {
      "BookingId": bookingId,
      "RiderId": riderId,
      "Action": action,
    });
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bookings/$path"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "Success": true,
          "Message": decoded is Map
              ? (decoded["Message"] ?? "Done")
              : "Done",
        };
      }

      return {
        "Success": false,
        "Message": _errorMessage(response, "Request failed"),
      };
    } catch (e) {
      print("Rider $path Exception: $e");
      return {"Success": false, "Message": "Cannot reach server."};
    }
  }
}
