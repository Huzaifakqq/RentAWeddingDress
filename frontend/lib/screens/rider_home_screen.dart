import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';

import '../config.dart';
import '../services/rider_service.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════════════
//  ✅ RIDER APP — Available orders | My Deliveries | Profile
// ══════════════════════════════════════════════════════════
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _tabIndex = 0;

  // Available tab
  List<dynamic> _available = [];
  bool _loadingAvailable = false;
  String _availableError = "";

  // My Deliveries tab
  List<dynamic> _mine = [];
  bool _loadingMine = false;
  String _mineError = "";

  // GPS
  double? _riderLat;
  double? _riderLng;
  bool _locating = false;

  double _radiusKm = 25; // selectable: 10 / 25 / 50

  // Ticker so countdowns stay live
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // refresh countdown labels
    });
    _acquireLocationThenLoad();
    _loadMyDeliveries();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ─────────────────────────────  GPS + data loading  ─────────────────────────

  Future<void> _acquireLocationThenLoad() async {
    setState(() => _locating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setAvailableError("Turn on GPS to see nearby deliveries.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setAvailableError("Location permission denied.");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _riderLat = pos.latitude;
      _riderLng = pos.longitude;

      await _loadAvailable();
    } catch (e) {
      _setAvailableError("Location error: $e");
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _setAvailableError(String msg) {
    if (!mounted) return;
    setState(() {
      _availableError = msg;
      _loadingAvailable = false;
    });
  }

  Future<void> _loadAvailable() async {
    if (_riderLat == null || _riderLng == null) {
      await _acquireLocationThenLoad();
      return;
    }

    setState(() {
      _loadingAvailable = true;
      _availableError = "";
    });

    final result = await RiderService.getAvailable(
      lat: _riderLat!,
      lng: _riderLng!,
      radiusKm: _radiusKm,
    );

    if (!mounted) return;
    setState(() {
      _loadingAvailable = false;
      if (result["Success"] == true) {
        _available = result["Orders"];
      } else {
        _availableError = result["Message"] ?? "Could not load orders";
      }
    });
  }

  Future<void> _loadMyDeliveries() async {
    if (UserSession.userId == null) return;

    setState(() {
      _loadingMine = true;
      _mineError = "";
    });

    final result = await RiderService.getMyDeliveries(UserSession.userId!);

    if (!mounted) return;
    setState(() {
      _loadingMine = false;
      if (result["Success"] == true) {
        _mine = result["Orders"];
      } else {
        _mineError = result["Message"] ?? "Could not load deliveries";
      }
    });
  }

  // ─────────────────────────────  Actions  ─────────────────────────

  Future<void> _accept(int bookingId) async {
    final result = await RiderService.accept(bookingId, UserSession.userId!);

    _showMessage(result["Message"] ?? "Done");
    if (result["Success"] == true) {
      await _loadAvailable();
      await _loadMyDeliveries();
    }
  }

  Future<void> _action(int bookingId, String action) async {
    final result = await RiderService.updateAction(
      bookingId,
      UserSession.userId!,
      action,
    );

    _showMessage(result["Message"] ?? "Done");
    if (result["Success"] == true) {
      await _loadMyDeliveries();
      await _loadAvailable();
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Open Google Maps directions → shop (pickup) or customer (drop-off)
  Future<void> _openMaps({
    double? lat,
    double? lng,
    String address = "",
  }) async {
    String url;
    if (lat != null && lng != null) {
      url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
    } else if (address.isNotEmpty) {
      url =
          "https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}";
    } else {
      _showMessage("No location available for this order.");
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage("Could not open maps.");
    }
  }

  void logout() {
    UserSession.userId = null;
    UserSession.name = null;
    UserSession.contact = null;
    UserSession.role = "customer";

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ─────────────────────────────  Helpers  ─────────────────────────

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _countdown(DateTime? start) {
    if (start == null) return "";
    final diff = start.difference(DateTime.now());
    if (diff.isNegative) return "delivery time now";
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h >= 1) return "in ${h}h ${m}m";
    return "in ${m}m";
  }

  double? _distanceKm(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (_riderLat == null || _riderLng == null) return null;
    return Geolocator.distanceBetween(
          _riderLat!,
          _riderLng!,
          lat,
          lng,
        ) /
        1000.0;
  }

  String _statusLabel(int? status) {
    switch (status) {
      case 1:
        return "Accepted";
      case 4:
        return "Picked";
      case 5:
        return "Delivered";
      default:
        return "Status $status";
    }
  }

  // ─────────────────────────────  Build  ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          const ["Nearby Deliveries", "My Deliveries", "Profile"][_tabIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildAvailableTab(),
          _buildMyDeliveriesTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black45,
          onTap: (i) {
            setState(() => _tabIndex = i);
            if (i == 0 && _available.isEmpty && !_loadingAvailable) {
              _loadAvailable();
            }
            if (i == 1 && !_loadingMine) _loadMyDeliveries();
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining),
              label: "Available",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: "My Deliveries",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────  TAB 1: AVAILABLE  ─────────────────────────

  Widget _buildAvailableTab() {
    return Column(
      children: [
        // Location / radius control panel
        Container(
          width: double.infinity,
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _riderLat == null
                          ? (_locating ? "Finding your location…" : "Location not set")
                          : "Near ${_riderLat!.toStringAsFixed(4)}, "
                              "${_riderLng!.toStringAsFixed(4)}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _locating ? null : _acquireLocationThenLoad,
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                    label: const Text(
                      "Refresh",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Radius chips: 10 / 25 / 50 km
              Row(
                children: [
                  const Text(
                    "Radius:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  for (final r in const [10.0, 25.0, 50.0])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text("${r.toInt()} km"),
                        selected: _radiusKm == r,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white12,
                        labelStyle: TextStyle(
                          color: _radiusKm == r ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() => _radiusKm = r);
                          _loadAvailable();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _loadingAvailable
              ? const Center(child: CircularProgressIndicator())
              : _availableError.isNotEmpty
                  ? _errorBox(_availableError, _acquireLocationThenLoad)
                  : RefreshIndicator(
                      onRefresh: _loadAvailable,
                      child: _available.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 70,
                                  color: Colors.black26,
                                ),
                                SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    "No deliveries open in your area yet.\n"
                                    "Orders appear 5 hours before delivery.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _available.length,
                              itemBuilder: (_, i) =>
                                  _orderCard(_available[i], available: true),
                            ),
                    ),
        ),
      ],
    );
  }

  // ─────────────────────────  TAB 2: MY DELIVERIES  ─────────────────────────

  Widget _buildMyDeliveriesTab() {
    if (_loadingMine) return const Center(child: CircularProgressIndicator());

    if (_mineError.isNotEmpty) {
      return _errorBox(_mineError, _loadMyDeliveries);
    }

    return RefreshIndicator(
      onRefresh: _loadMyDeliveries,
      child: _mine.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.local_shipping_outlined, size: 70, color: Colors.black26),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    "No active deliveries.\nAccept an order from the Available tab.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mine.length,
              itemBuilder: (_, i) => _orderCard(_mine[i], available: false),
            ),
    );
  }

  // ─────────────────────────  TAB 3: PROFILE  ─────────────────────────

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(25),
      children: [
        const SizedBox(height: 30),
        const CircleAvatar(
          radius: 45,
          backgroundColor: Colors.black,
          child: Icon(Icons.delivery_dining, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            UserSession.name ?? "Rider",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            UserSession.contact ?? "",
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "RIDERS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),

        _profileRow(Icons.radar, "Delivery radius", "${_radiusKm.toInt()} km"),
        _profileRow(
          Icons.timer_outlined,
          "Order window",
          "5 hours before delivery",
        ),
        _profileRow(
          Icons.check_circle_outline,
          "Accepted deliveries",
          "${_mine.length}",
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: logout,
            child: const Text("Logout"),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────  Shared widgets  ─────────────────────────

  Widget _errorBox(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: onRetry,
              child: const Text("Try Again", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // One order card — used by both Available and My Deliveries tabs
  Widget _orderCard(dynamic order, {required bool available}) {
    final int bookingId = order["BookingId"];
    final int? status = order["Status"];
    final DateTime? start = _parseDate(order["StartDate"]);
    final DateTime? end = _parseDate(order["EndDate"]);

    final double? shopLat =
        order["ShopLat"] == null ? null : (order["ShopLat"] as num).toDouble();
    final double? shopLng =
        order["ShopLng"] == null ? null : (order["ShopLng"] as num).toDouble();
    final double? delLat = order["DeliveryLat"] == null
        ? null
        : (order["DeliveryLat"] as num).toDouble();
    final double? delLng = order["DeliveryLng"] == null
        ? null
        : (order["DeliveryLng"] as num).toDouble();

    final distKm = _distanceKm(shopLat, shopLng);
    final countdown = _countdown(start);
    final image = order["DressImage"] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dress thumbnail + title + countdown ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: image != null && image.isNotEmpty
                        ? Image.network(
                            "${Config.imageBaseUrl}$image",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _FallbackThumb(),
                          )
                        : const _FallbackThumb(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order["DressTitle"] ?? "Wedding dress",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Rs. ${order["TotalPrice"] ?? 0}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip(
                            Icons.event,
                            start == null
                                ? "—"
                                : "${start.day}/${start.month}/${start.year}",
                          ),
                          const SizedBox(width: 6),
                          if (countdown.isNotEmpty)
                            _chip(
                              Icons.timer_outlined,
                              countdown,
                              urgent: start != null &&
                                  start.isAfter(DateTime.now()) &&
                                  start.difference(DateTime.now()).inHours < 1,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!available)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 5
                          ? Colors.green.shade50
                          : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: status == 5 ? Colors.green.shade800 : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Delivery details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                _detailRow(
                  Icons.person_outline,
                  "${order["CustomerName"] ?? "Customer"} · ${order["CustomerContact"] ?? ""}",
                ),
                _detailRow(
                  Icons.location_on_outlined,
                  order["Address"] ?? "No address",
                ),
                _detailRow(
                  Icons.calendar_today,
                  end == null
                      ? "${order["NoOfDays"] ?? 0} day(s)"
                      : "Return by ${end.day}/${end.month}/${end.year}",
                ),
                if (distKm != null)
                  _detailRow(
                    Icons.storefront_outlined,
                    "Shop ${distKm.toStringAsFixed(1)} km away",
                  ),
              ],
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _openMaps(
                      lat: status == 4 ? delLat : shopLat,
                      lng: status == 4 ? delLng : shopLng,
                      address: order["Address"] ?? "",
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text("Open in Maps"),
                  ),
                ),
                const SizedBox(width: 10),
                if (available)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _accept(bookingId),
                      child: const Text("Accept"),
                    ),
                  )
                else if (status == 1)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _action(bookingId, "picked"),
                      child: const Text("Mark Picked"),
                    ),
                  )
                else if (status == 4)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _action(bookingId, "delivered"),
                      child: const Text("Mark Delivered"),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Delivered ✓",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, {bool urgent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: urgent ? Colors.red : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: urgent ? Colors.red : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.checkroom, color: Colors.black26),
    );
  }
}
