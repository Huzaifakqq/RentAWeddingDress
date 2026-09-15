import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/screens/my_rentals_screen.dart';
import 'package:rent_a_wedding_dress/screens/upload_dress_screen.dart';
import '../models/dress_model.dart';
import '../services/dress_service.dart';
import 'filter_bottom_sheet.dart';
import 'home_screen.dart';
import '../config.dart';
import 'dress_details_screen.dart';

class DressesScreen extends StatefulWidget {
  const DressesScreen({super.key});

  @override
  State<DressesScreen> createState() => _DressesScreenState();
}

class _DressesScreenState extends State<DressesScreen> {
  List<DressModel> dresses = [];
  bool isLoading = true;
  Map<String, dynamic> currentFilters = {};

  @override
  void initState() {
    super.initState();
    fetchDresses();
  }

  Future<void> fetchDresses({Map<String, dynamic>? filters}) async {
    setState(() => isLoading = true);

    final result = await DressService.filterDresses(filters ?? {});

    setState(() {
      dresses = result;
      isLoading = false;
    });
  }

  void openFilter() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(existingFilters: currentFilters),
    );

    if (result != null) {
      currentFilters = result;
      fetchDresses(filters: currentFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ✅ TOP LOGO BAR (LESS PADDING NOW)
            Container(
              color: const Color(0xFFF3F4F6),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/logo.png", height: 26),
                      const SizedBox(width: 6),
                      const Text(
                        "WedDress",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(height: 1, color: const Color(0xFFE5E5E5)),
                ],
              ),
            ),

            // ✅ SEARCH + FILTER (REDUCED GAP)
            Container(
              color: const Color(0xFFF3F4F6),
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search dresses...",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        currentFilters["Search"] = value;
                        fetchDresses(filters: currentFilters);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: openFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Filter",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ GRID
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dresses.isEmpty
                  ? const Center(child: Text("No Dresses Found"))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: dresses.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220, // width per card
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75, // more relaxed
                          ),
                      itemBuilder: (context, index) {
                        final dress = dresses[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DressDetailsScreen(dressId: dress.id),
                              ),
                            );
                          },
                          child: buildDressCard(dress),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ✅ FOOTER WITH SOFT SHADOW
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
          currentIndex: 1,
          backgroundColor: const Color(0xFFF3F4F6),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
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
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  Widget buildDressCard(DressModel dress) {
    return Card(
      color: Colors.white, // ✅ WHITE CARD
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
                          const Icon(Icons.star, color: Colors.white, size: 16),
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

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              dress.title,
              maxLines: 1, // ✅ Force single line
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14, // ✅ Reduced size
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
