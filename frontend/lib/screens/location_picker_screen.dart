import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen Google Map picker:
/// - Opens at current GPS location
/// - Tap anywhere to move the pin
/// Returns the selected LatLng.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? mapController;
  LatLng? selected;

  @override
  void initState() {
    super.initState();
    selected = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(24.8607, 67.0011); // Karachi fallback
    _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final myLoc = LatLng(pos.latitude, pos.longitude);

      if (widget.initialLat == null) {
        setState(() => selected = myLoc);
      }

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(myLoc, 15));
    } catch (e) {
      print("Map location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Tap map to set location"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selected!,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              _goToMyLocation();
            },
            onTap: (latLng) {
              setState(() => selected = latLng);
            },
            markers: {
              if (selected != null)
                Marker(
                  markerId: const MarkerId("selected"),
                  position: selected!,
                  draggable: true,
                  onDragEnd: (latLng) {
                    setState(() => selected = latLng);
                  },
                ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                if (selected != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Pin: ${selected!.latitude.toStringAsFixed(5)}, "
                      "${selected!.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, selected);
                    },
                    child: const Text(
                      "Use This Location",
                      style: TextStyle(color: Colors.white),
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
}
