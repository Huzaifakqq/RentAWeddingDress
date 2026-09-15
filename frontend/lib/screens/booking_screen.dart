import 'package:flutter/material.dart';
import '../services/dress_service.dart';
import '../services/booking_service.dart';
import '../models/user_session.dart';

class BookingScreen extends StatefulWidget {
  final int dressId;
  final double rentPerDay;
  final String dressTitle;

  const BookingScreen({
    super.key,
    required this.dressId,
    required this.rentPerDay,
    required this.dressTitle,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTimeRange? selectedDateRange;

  List<dynamic> addresses = [];
  int? selectedAddressId;

  bool isChecking = false;
  bool isConfirming = false;
  bool? isAvailable;

  int numberOfDays = 0;
  double totalCost = 0;
  String message = "";

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  // ✅ Load saved addresses
  Future<void> loadAddresses() async {
    if (UserSession.userId == null) return;

    final result = await DressService.getUserAddresses(UserSession.userId!);

    setState(() {
      addresses = result;
      if (addresses.isNotEmpty) {
        selectedAddressId = addresses.first["UA_id"];
      }
    });
  }

  // ✅ Pick Date
  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        isAvailable = null;
      });
    }
  }

  // ✅ Check Availability
  Future<void> checkAvailability() async {
    if (selectedDateRange == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select dates first")));
      return;
    }

    setState(() => isChecking = true);

    final result = await BookingService.checkAvailability({
      "DressId": widget.dressId,
      "StartDate": selectedDateRange!.start.toIso8601String(),
      "EndDate": selectedDateRange!.end.toIso8601String(),
    });

    setState(() => isChecking = false);

    if (result != null) {
      setState(() {
        isAvailable = result["IsAvailable"];
        numberOfDays = result["NumberOfDays"] ?? 0;
        totalCost = (result["TotalCost"] as num?)?.toDouble() ?? 0;
        message = result["Message"] ?? "";
      });
    }
  }

  // ✅ Confirm Booking
  Future<void> confirmBooking() async {
    if (UserSession.userId == null ||
        selectedDateRange == null ||
        selectedAddressId == null) {
      return;
    }

    setState(() => isConfirming = true);

    final success = await BookingService.confirmBooking({
      "UserId": UserSession.userId,
      "DressId": widget.dressId,
      "UserAddressId": selectedAddressId,
      "StartDate": selectedDateRange!.start.toIso8601String(),
      "EndDate": selectedDateRange!.end.toIso8601String(),
    });

    setState(() => isConfirming = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking Confirmed")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking Failed")));
    }
  }

  // ✅ Add Address Bottom Sheet
  Future<void> addNewAddress() async {
    TextEditingController controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Address",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Enter full address",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    if (controller.text.isEmpty) return;

                    final success = await DressService.addAddress({
                      "U_id": UserSession.userId,
                      "Address": controller.text,
                    });

                    if (success) {
                      Navigator.pop(context);
                      await loadAddresses();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Address added successfully"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to add address")),
                      );
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget buildDetailRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text(
          "Select Rental Dates",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dressTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Date Picker
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: pickDateRange,
                  child: Text(
                    selectedDateRange == null
                        ? "Select Start & End Date"
                        : "${selectedDateRange!.start.toLocal().toString().split(' ')[0]} - "
                              "${selectedDateRange!.end.toLocal().toString().split(' ')[0]}",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ✅ Check Availability
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: isChecking ? null : checkAvailability,
                  child: isChecking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Check Availability",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Select Address",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              if (addresses.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "No address found",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: addNewAddress,
                        child: const Text(
                          "Add New Address",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedAddressId,
                      items: addresses.map<DropdownMenuItem<int>>((address) {
                        return DropdownMenuItem<int>(
                          value: address["UA_id"],
                          child: Text(address["Address"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAddressId = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: addNewAddress,
                        child: const Text(
                          "Add Another Address",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              if (isAvailable != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Booking Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    buildDetailRow(
                      "Rental per day",
                      "Rs.${widget.rentPerDay.toInt()}",
                    ),

                    const SizedBox(height: 12),

                    buildDetailRow("Number of days", numberOfDays.toString()),

                    const SizedBox(height: 12),

                    const Divider(height: 30),

                    buildDetailRow(
                      "Total Cost",
                      "Rs.${totalCost.toInt()}",
                      isBold: true,
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isAvailable == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: isAvailable == true && !isConfirming
                      ? confirmBooking
                      : null,
                  child: isConfirming
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm Booking",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
