import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/screens/review_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/user_session.dart';
import '../services/rental_service.dart';
import '../services/booking_service.dart';
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

  // ✅ CANCEL BOOKING — anytime; penalty within 3 days shown as Rs. 0
  Future<void> cancelBooking(dynamic booking) async {
    int bookingId = booking["BookingId"];
    DateTime startDate = DateTime.parse(booking["StartDate"]);
    int daysBefore = startDate.difference(DateTime.now()).inDays;

    bool hasPenalty = daysBefore < 3;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Days until delivery: $daysBefore"),
            const SizedBox(height: 10),
            if (hasPenalty)
              const Text(
                "Penalty: Rs. 0\n(late cancellation — waived for now)",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                "Free cancellation (3+ days before delivery)",
                style: TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 10),
            const Text(
              "You can cancel or reschedule anytime.",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Booking"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await BookingService.cancelBooking(
                UserSession.userId!,
                bookingId,
              );
              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result["Message"] ?? "Cancelled")),
                );
                await loadRentals();
              }
            },
            child: const Text(
              "Cancel Booking",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ RESCHEDULE BOOKING — booked days are greyed out & unselectable
  Future<void> rescheduleBooking(dynamic booking) async {
    int bookingId = booking["BookingId"];
    int dressId = booking["DressId"];
    DateTime currentStart = DateTime.parse(booking["StartDate"]);
    DateTime currentEnd = DateTime.parse(booking["EndDate"]);
    int daysBefore = currentStart.difference(DateTime.now()).inDays;
    bool hasPenalty = daysBefore < 3;

    // ✅ Load other bookings' dates for this dress (exclude this booking)
    final bookedRaw = await BookingService.getBookedDates(
      dressId,
      excludeBookingId: bookingId,
    );

    // Build a set of blocked calendar days (start..end inclusive)
    final blocked = <DateTime>{};
    for (final r in bookedRaw) {
      final s = DateTime.parse(r["Start"] as String);
      final e = DateTime.parse(r["End"] as String);
      for (var d = DateTime(s.year, s.month, s.day);
          !d.isAfter(DateTime(e.year, e.month, e.day));
          d = d.add(const Duration(days: 1))) {
        blocked.add(d);
      }
    }

    final newRange = await _pickRangeWithBlockedDays(
      currentStart: currentStart,
      currentEnd: currentEnd,
      blocked: blocked,
      hasBlockedDates: bookedRaw.isNotEmpty,
    );

    if (newRange == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reschedule Booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New dates: ${newRange.start.toLocal().toString().split(' ')[0]} "
              "- ${newRange.end.toLocal().toString().split(' ')[0]}",
            ),
            const SizedBox(height: 10),
            Text("Days until current delivery: $daysBefore"),
            const SizedBox(height: 10),
            if (hasPenalty)
              const Text(
                "Penalty: Rs. 0\n(late reschedule — waived for now)",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                "No penalty (3+ days before delivery)",
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Confirm Reschedule",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await BookingService.rescheduleBooking(
        UserSession.userId!,
        bookingId,
        newRange.start.toIso8601String(),
        newRange.end.toIso8601String(),
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["Message"] ?? "Rescheduled")),
        );
        await loadRentals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reschedule failed")),
        );
      }
    }
  }

  // ✅ Calendar dialog: booked days greyed out & unselectable
  Future<DateTimeRange?> _pickRangeWithBlockedDays({
    required DateTime currentStart,
    required DateTime currentEnd,
    required Set<DateTime> blocked,
    required bool hasBlockedDates,
  }) {
    DateTime? start = DateTime(currentStart.year, currentStart.month, currentStart.day);
    DateTime? end = DateTime(currentEnd.year, currentEnd.month, currentEnd.day);
    DateTime focused = start;

    bool isBlocked(DateTime day) {
      final d = DateTime(day.year, day.month, day.day);
      return blocked.contains(d);
    }

    // A range is invalid if ANY day inside it is blocked
    bool rangeHitsBlocked(DateTime s, DateTime e) {
      for (var d = DateTime(s.year, s.month, s.day);
          !d.isAfter(DateTime(e.year, e.month, e.day));
          d = d.add(const Duration(days: 1))) {
        if (blocked.contains(d)) return true;
      }
      return false;
    }

    return showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) {
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Select New Dates",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 330,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Legend
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Booked — not available",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(2030),
                        focusedDay: focused.isBefore(DateTime.now())
                            ? DateTime.now()
                            : focused,
                        currentDay: DateTime.now(),
                        rangeStartDay: start,
                        rangeEndDay: end,
                        enabledDayPredicate: (day) => !isBlocked(day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setDialogState(() {
                            focused = focusedDay;
                            final d = DateTime(
                              selectedDay.year,
                              selectedDay.month,
                              selectedDay.day,
                            );

                            if (isBlocked(d)) {
                              errorText = "This date is already booked.";
                              return;
                            }

                            if (start == null || end != null) {
                              // begin new range
                              start = d;
                              end = null;
                              errorText = null;
                            } else if (d.isBefore(start!)) {
                              start = d;
                              end = null;
                              errorText = null;
                            } else if (rangeHitsBlocked(start!, d)) {
                              errorText =
                                  "Range includes booked dates. Pick different dates.";
                            } else {
                              end = d;
                              errorText = null;
                            }
                          });
                        },
                        onRangeSelected: (s, e, f) {
                          setDialogState(() {
                            focused = f;
                            start = s;
                            end = e;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          rangeHighlightColor: Colors.black12,
                          todayDecoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          defaultDecoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          disabledDecoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          disabledTextStyle: TextStyle(
                            color: Colors.red.shade400,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      if (hasBlockedDates) ...[
                        const SizedBox(height: 6),
                        const Text(
                          "Grey dates are already booked for this dress.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],

                      if (start != null && end != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          "${start!.toLocal().toString().split(' ')[0]} → "
                          "${end!.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: (start != null && end != null)
                      ? () => Navigator.pop(
                            ctx,
                            DateTimeRange(start: start!, end: end!),
                          )
                      : null,
                  child: const Text(
                    "Select",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

    String? sizeSummary = booking["SizeSummary"];

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
                      if (sizeSummary != null && sizeSummary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sizeSummary,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
      // ✅ CUSTOMER VIEW — cancel/reschedule anytime (status 0 and 1)
      switch (status) {
        case 0:
        case 1:
          buttons.add(actionButton("Cancel", () => cancelBooking(booking)));
          buttons.add(const SizedBox(width: 10));
          buttons.add(
            actionButton("Reschedule", () => rescheduleBooking(booking)),
          );
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
