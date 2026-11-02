import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/screens/home_screen.dart';
import 'package:rent_a_wedding_dress/screens/my_rentals_screen.dart';
import 'package:rent_a_wedding_dress/screens/upload_dress_screen.dart';
import '../models/dress_model.dart';
import '../models/user_session.dart';
import '../services/dress_service.dart';
import '../config.dart';
import 'dress_details_screen.dart';
import 'dresses_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<DressModel> listings = [];
  bool isLoading = true;
  String loadError = "";

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    setState(() {
      isLoading = true;
      loadError = "";
    });

    if (UserSession.userId == null) {
      setState(() {
        isLoading = false;
        loadError = "Not logged in";
      });
      return;
    }

    final result = await DressService.getMyListings(UserSession.userId!);

    if (mounted) {
      setState(() {
        listings = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Listings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: loadListings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ COUNT SUMMARY
          if (!isLoading && loadError.isEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(15, 4, 15, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                "You have uploaded ${listings.length} listing${listings.length == 1 ? "" : "s"}",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),

          // ✅ CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loadError.isNotEmpty
                ? Center(
                    child: Text(
                      loadError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : listings.isEmpty
                ? buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: listings.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                    itemBuilder: (context, index) {
                      final dress = listings[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DressDetailsScreen(dressId: dress.id),
                            ),
                          ).then((_) => loadListings()); // refresh on return
                        },
                        child: buildListingCard(dress),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ✅ FOOTER — same 5 tabs as the rest of the app
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 4,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFF3F4F6),
          elevation: 0,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: "My Listings",
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DressesScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
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

  // ✅ EMPTY STATE — nothing uploaded yet
  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 15),
            const Text(
              "You haven't uploaded any dress yet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadDressScreen()),
                ).then((_) => loadListings());
              },
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text(
                "Upload Your First Dress",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CARD — same layout as the browse screen so copies look familiar
  Widget buildListingCard(DressModel dress) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: dress.image != null
                      ? Image.network(
                          "${Config.imageBaseUrl}${dress.image}",
                          fit: BoxFit.cover,
                          cacheWidth: 480,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(color: Colors.grey[300]),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs.${dress.rentPrice.toInt()}/day",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dress.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                buildBadge(dress.gender),
                const SizedBox(width: 6),
                if (dress.occasion != null) buildBadge(dress.occasion!),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Age + condition (identifies each copy)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (dress.ageDisplay.isNotEmpty) ...[
                  const Icon(Icons.history, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      dress.ageDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
                if (dress.ageDisplay.isNotEmpty && dress.condition > 0)
                  const SizedBox(width: 8),
                if (dress.condition > 0)
                  Text(
                    "Cond ${dress.condition}/10",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              dress.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
