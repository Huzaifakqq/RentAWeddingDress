import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';
import 'package:rent_a_wedding_dress/screens/login_screen.dart';
import 'package:rent_a_wedding_dress/screens/my_rentals_screen.dart';
import 'package:rent_a_wedding_dress/screens/upload_dress_screen.dart';
import 'dresses_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    const SizedBox(width: 40), // for balance

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
