import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/screens/review_screen.dart';
import '../models/user_session.dart';
import '../services/rental_service.dart';
import '../config.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  List<dynamic> customerBookings = [];
  List<dynamic> ownerBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRentals();
  }

  Future<void> loadRentals() async {
    if (UserSession.userId == null) return;

    final customer = await RentalService.getCustomerRentals(
      UserSession.userId!,
    );

    final owner = await RentalService.getOwnerBookings(UserSession.userId!);

    setState(() {
      customerBookings = customer;
      ownerBookings = owner;
      isLoading = false;
    });
  }

  Future<void> updateStatus(int bookingId, int status) async {
    final success = await RentalService.updateBookingStatus(bookingId, status);

    if (success) {
      await loadRentals();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid action")));
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
      case 4:
      case 5:
        return Colors.blue;
      case 6:
        return Colors.purple;
      case 7:
        return Colors.green;
      case 2:
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(int status) {
    switch (status) {
      case 0:
        return "Pending";
      case 1:
        return "Accepted";
      case 2:
        return "Cancelled";
      case 3:
        return "Rejected";
      case 4:
        return "Picked";
      case 5:
        return "Active";
      case 6:
        return "Return Requested";
      case 7:
        return "Completed";
      default:
        return "Unknown";
    }
  }

  Widget buildBookingCard(dynamic booking, bool isOwner) {
    int status = booking["Status"];

    DateTime startDate = DateTime.parse(booking["StartDate"]);
    DateTime endDate = DateTime.parse(booking["EndDate"]);
    DateTime today = DateTime.now();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "${Config.imageBaseUrl}${booking["Image"]}",
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking["DressTitle"],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${booking["StartDate"].split("T")[0]} to ${booking["EndDate"].split("T")[0]}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Rs.${booking["TotalPrice"]}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatusText(status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            buildActionButtons(
              booking,
              status,
              isOwner,
              startDate,
              endDate,
              today,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButtons(
    dynamic booking,
    int status,
    bool isOwner,
    DateTime startDate,
    DateTime endDate,
    DateTime today,
  ) {
    List<Widget> buttons = [];
    int bookingId = booking["BookingId"];

    if (!isOwner) {
      // ✅ CUSTOMER VIEW
      switch (status) {
        case 0:
          buttons.add(actionButton("Cancel", () => updateStatus(bookingId, 2)));
          break;

        case 4:
          buttons.add(
            actionButton("Confirm Pickup", () => updateStatus(bookingId, 5)),
          );
          break;

        case 5:
          if (!today.isBefore(endDate)) {
            buttons.add(
              actionButton("Return Dress", () => updateStatus(bookingId, 6)),
            );
          } else {
            buttons.add(
              Expanded(
                child: Text(
                  "Return on ${booking["EndDate"].split("T")[0]}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          break;

        case 7:
          var ratingValue = booking["Rating"];

          if (ratingValue != null && ratingValue > 0) {
            // ✅ Already reviewed
            buttons.clear(); // IMPORTANT

            buttons.add(
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Reviewed ",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        ratingValue.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // ✅ Not reviewed yet
            buttons.clear(); // IMPORTANT

            buttons.add(
              actionButton("Write Review", () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      bookingId: booking["BookingId"],
                      dressId: booking["DressId"],
                    ),
                  ),
                );

                if (result == true) {
                  loadRentals();
                }
              }),
            );
          }

          break;
      }
    } else {
      // ✅ OWNER VIEW
      switch (status) {
        case 0:
          buttons.add(actionButton("Accept", () => updateStatus(bookingId, 1)));
          buttons.add(const SizedBox(width: 10));
          buttons.add(actionButton("Reject", () => updateStatus(bookingId, 3)));
          break;

        case 1:
          if (!today.isBefore(startDate)) {
            buttons.add(
              actionButton("Mark Picked", () => updateStatus(bookingId, 4)),
            );
          } else {
            buttons.add(
              Expanded(
                child: Text(
                  "Pickup on ${booking["StartDate"].split("T")[0]}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          break;

        case 6:
          buttons.add(
            actionButton("Confirm Return", () => updateStatus(bookingId, 7)),
          );
          break;
      }
    }

    return Row(children: buttons);
  }

  Widget actionButton(String text, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text("My Rentals", style: TextStyle(color: Colors.black)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customerBookings.isNotEmpty)
                    const Text(
                      "My Bookings",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),

                  ...customerBookings.map((b) => buildBookingCard(b, false)),

                  if (ownerBookings.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "Bookings On My Dresses",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),

                  ...ownerBookings.map((b) => buildBookingCard(b, true)),
                ],
              ),
            ),
    );
  }
}
