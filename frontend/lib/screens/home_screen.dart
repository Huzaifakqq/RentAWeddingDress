import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';
import 'package:rent_a_wedding_dress/screens/login_screen.dart';
import 'package:rent_a_wedding_dress/screens/my_rentals_screen.dart';
import 'package:rent_a_wedding_dress/screens/upload_dress_screen.dart';
import 'package:rent_a_wedding_dress/services/booking_service.dart';
import 'package:rent_a_wedding_dress/services/dress_service.dart';
import 'dresses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSettingLocation = false;

  // ✅ CREDIT BALANCE (shown in header card)
  double? creditBalance;
  bool isLoadingCredit = true;

  @override
  void initState() {
    super.initState();
    loadCredit();
  }

  Future<void> loadCredit() async {
    if (UserSession.userId == null) {
      if (mounted) setState(() => isLoadingCredit = false);
      return;
    }

    final balance = await BookingService.getCredit(UserSession.userId!);

    if (mounted) {
      setState(() {
        creditBalance = balance;
        isLoadingCredit = false;
      });
    }
  }

  // ✅ One button sets shop location for ALL dresses of this owner
  Future<void> setShopLocation() async {
    if (UserSession.userId == null) return;

    setState(() => isSettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("Turn on GPS first");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage("Location permission denied");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = await DressService.updateShopLocation(
        UserSession.userId!,
        pos.latitude,
        pos.longitude,
      );

      if (result != null && result["Count"] != null) {
        _showMessage(
          "Shop location updated for ${result["Count"]} dress(es)",
        );
      } else {
        _showMessage(result?["Error"] ?? "No dresses found to update");
      }
    } catch (e) {
      _showMessage("Location error: $e");
    } finally {
      if (mounted) setState(() => isSettingLocation = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Container(
                color: Color(0xFFF3F4F6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Row(
                      children: [
                        Image.asset("assets/images/logo.png", height: 28),
                        const SizedBox(width: 8),
                        const Text(
                          "WedDress",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        logout(context);
                      },
                    ),
                  ],
                ),
              ),

              // ✅ CREDIT BALANCE
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: (creditBalance ?? 0) < 0
                            ? Colors.red
                            : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Credit Balance",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            isLoadingCredit
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Rs.${(creditBalance ?? 0).toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: (creditBalance ?? 0) < 0
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      if (!isLoadingCredit && (creditBalance ?? 0) < 0)
                        const Flexible(
                          child: Text(
                            "Due — added to your next booking",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        )
                      else
                        const Flexible(
                          child: Text(
                            "Top-up managed by admin",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ SHOP LOCATION — one tap updates all dresses
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: isSettingLocation ? null : setShopLocation,
                    icon: isSettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.store, color: Colors.black),
                    label: const Text(
                      "Set Shop Location (updates all dresses)",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // BANNER
              Stack(
                children: [
                  Image.asset(
                    "assets/images/banner.png",
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "How it works",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              buildStep(
                "assets/images/hanger.png",
                "PICK A DATE",
                "Choose when and for how long you would like to rent the outfit of your choice.",
              ),

              const SizedBox(height: 50),

              buildStep(
                "assets/images/dress.png",
                "BOOK YOUR OUTFIT",
                "Browse through our vast collection of beautiful designer ensembles and find your perfect style.",
              ),

              const SizedBox(height: 50),

              buildStep(
                "assets/images/box.png",
                "FEEL AMAZING",
                "Feel absolutely amazing every time you Rent It! You're ready to wear your beautiful outfit and take on any event in style!",
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ✅ FOOTER
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -3), // shadow above
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFF3F4F6),
          elevation: 0, // ✅ remove default shadow
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: "Dresses",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upload),
              label: "Upload Dress",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: "My Rentals",
            ),
          ],
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DressesScreen()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UploadDressScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyRentalsScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  void logout(BuildContext context) {
    UserSession.userId = null;
    UserSession.name = null;
    UserSession.contact = null;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget buildStep(String image, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          Image.asset(image, height: 90),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
