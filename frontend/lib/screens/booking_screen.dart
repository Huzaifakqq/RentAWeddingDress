import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/dress_service.dart';
import '../services/booking_service.dart';
import '../models/user_session.dart';
import 'location_picker_screen.dart';

class BookingScreen extends StatefulWidget {
  final int dressId;
  final double rentPerDay;
  final String dressTitle;
  final List<dynamic> sizeStocks;

  const BookingScreen({
    super.key,
    required this.dressId,
    required this.rentPerDay,
    required this.dressTitle,
    required this.sizeStocks,
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

  // ✅ Multi-size: SizeId -> quantity (0 = not selected)
  Map<int, int> sizeQty = {};

  // ✅ Map pin for delivery location (shown in UI / address sheet)
  double? deliveryLat;
  double? deliveryLng;
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final s in widget.sizeStocks) {
      sizeQty[s['SizeId']] = 0;
    }
    loadAddresses();
  }

  int get totalSelectedQty =>
      sizeQty.values.where((q) => q > 0).fold(0, (a, b) => a + b);

  List<Map<String, dynamic>> get selectedItems {
    final items = <Map<String, dynamic>>[];
    sizeQty.forEach((sizeId, qty) {
      if (qty > 0) {
        items.add({"SizeId": sizeId, "Quantity": qty});
      }
    });
    return items;
  }

  void resetAvailability() {
    isAvailable = null;
    message = "";
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
        resetAvailability();
      });
    }
  }

  // ✅ Open Google Map picker for delivery pin
  Future<void> openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: deliveryLat,
          initialLng: deliveryLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        deliveryLat = result.latitude;
        deliveryLng = result.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Location set: ${result.latitude.toStringAsFixed(4)}, "
            "${result.longitude.toStringAsFixed(4)}",
          ),
        ),
      );
    }
  }

  // ✅ Check Availability (multi-size)
  Future<void> checkAvailability() async {
    if (selectedDateRange == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select dates first")));
      return;
    }

    if (totalSelectedQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select size quantities first")),
      );
      return;
    }

    setState(() => isChecking = true);

    final result = await BookingService.checkAvailability({
      "DressId": widget.dressId,
      "StartDate": selectedDateRange!.start.toIso8601String(),
      "EndDate": selectedDateRange!.end.toIso8601String(),
      "Items": selectedItems,
    });

    setState(() => isChecking = false);

    if (result != null) {
      setState(() {
        isAvailable = result["IsAvailable"] == true;
        numberOfDays = result["NumberOfDays"] ?? 0;
        totalCost = (result["TotalCost"] as num?)?.toDouble() ?? 0;
        message = result["Message"]?.toString() ??
            (isAvailable == true
                ? "Available"
                : "Could not check availability.");
      });
    } else {
      setState(() {
        isAvailable = false;
        message = "Cannot reach server. Is the backend running?";
      });
    }
  }

  // ✅ Confirm Booking (multi-size)
  Future<void> confirmBooking() async {
    if (UserSession.userId == null ||
        selectedDateRange == null ||
        selectedAddressId == null ||
        totalSelectedQty == 0) {
      return;
    }

    setState(() => isConfirming = true);

    final result = await BookingService.confirmBooking({
      "UserId": UserSession.userId,
      "DressId": widget.dressId,
      "UserAddressId": selectedAddressId,
      "StartDate": selectedDateRange!.start.toIso8601String(),
      "EndDate": selectedDateRange!.end.toIso8601String(),
      "Items": selectedItems,
    });

    setState(() => isConfirming = false);

    if (result["Success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["Message"] ?? "Booking Confirmed")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["Message"] ?? "Booking Failed")),
      );
    }
  }

  // ✅ Add Address Bottom Sheet (map + exact address text box)
  Future<void> addNewAddress() async {
    TextEditingController controller = TextEditingController();
    double? lat = deliveryLat;
    double? lng = deliveryLng;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  const SizedBox(height: 15),

                  // ✅ MAP PICKER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              initialLat: lat,
                              initialLng: lng,
                            ),
                          ),
                        );
                        if (result != null) {
                          setSheetState(() {
                            lat = result.latitude;
                            lng = result.longitude;
                          });
                          setState(() {
                            deliveryLat = result.latitude;
                            deliveryLng = result.longitude;
                          });
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.black),
                      label: Text(
                        lat != null
                            ? "Location set (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})"
                            : "Pick Location on Map",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          "Exact address: house number, office, house name...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
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
                            const SnackBar(
                                content: Text("Failed to add address")),
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

  String sizeName(dynamic s) => s['SizeName']?.toString() ?? "?";

  int sizeStockOf(dynamic s) => (s['Stock'] as num?)?.toInt() ?? 1;

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

              const SizedBox(height: 20),

              // ✅ MULTI-SIZE SELECTION (2 medium + 1 small + 4 XL in one order)
              const Text(
                "Select Sizes & Quantities",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              ...widget.sizeStocks.map((s) {
                final sizeId = s['SizeId'];
                final qty = sizeQty[sizeId] ?? 0;
                final stock = sizeStockOf(s);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sizeName(s),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "$stock available",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 0
                            ? () {
                                setState(() {
                                  sizeQty[sizeId] = qty - 1;
                                  resetAvailability();
                                });
                              }
                            : null,
                      ),
                      Text(
                        "$qty",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: qty < stock
                            ? () {
                                setState(() {
                                  sizeQty[sizeId] = qty + 1;
                                  resetAvailability();
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                );
              }),

              if (totalSelectedQty > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    "Total items: $totalSelectedQty",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),

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

              // ✅ DELIVERY LOCATION (map button + exact address)
              const Text(
                "Delivery Location",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: openMapPicker,
                  icon: const Icon(Icons.map, color: Colors.black),
                  label: Text(
                    deliveryLat != null
                        ? "Location set — tap to change"
                        : "Pick Location on Map",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),

              if (deliveryLat != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "${deliveryLat!.toStringAsFixed(4)}, "
                    "${deliveryLng!.toStringAsFixed(4)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),

              const SizedBox(height: 15),

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

                    buildDetailRow(
                      "Total items",
                      totalSelectedQty.toString(),
                    ),

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
