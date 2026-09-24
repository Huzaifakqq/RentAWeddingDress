import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';
import 'package:rent_a_wedding_dress/screens/booking_screen.dart';
import 'package:rent_a_wedding_dress/screens/all_ratings_screen.dart';
import '../models/dress_details_model.dart';
import '../services/dress_service.dart';
import '../config.dart';

class DressDetailsScreen extends StatefulWidget {
  final int dressId;

  const DressDetailsScreen({super.key, required this.dressId});

  @override
  State<DressDetailsScreen> createState() => _DressDetailsScreenState();
}

class _DressDetailsScreenState extends State<DressDetailsScreen> {
  DressDetailsModel? dress;
  bool isLoading = true;
  bool isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    final result = await DressService.getDressDetails(widget.dressId);

    setState(() {
      dress = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ BACK BUTTON
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // ✅ IMAGE SLIDER
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: PageView.builder(
                            itemCount: dress!.images.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                "${Config.imageBaseUrl}${dress!.images[index]}",
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ TITLE
                          Text(
                            dress!.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ✅ PRICE
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Rs.${dress!.rentPrice.toInt()} ",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: "/ day",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          buildInfoRow("Gender:", dress!.gender),
                          buildInfoRow(
                            "Occasion:",
                            dress!.occasions.join(", "),
                          ),
                          buildInfoRow("Condition:", "${dress!.condition}/10"),
                          buildInfoRow("Dress Age:", dress!.ageDisplay),
                          buildInfoRow(
                            "Sizes:",
                            dress!.sizeStocks
                                .map((s) => "${s.sizeName} (${s.stock})")
                                .join(", "),
                          ),

                          const SizedBox(height: 15),

                          // ✅ EXPANDABLE DESCRIPTION
                          const Text(
                            "Description:",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            dress!.description,
                            maxLines: isDescriptionExpanded ? null : 3,
                            overflow: isDescriptionExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),

                          if (dress!.description.length > 100)
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isDescriptionExpanded =
                                        !isDescriptionExpanded;
                                  });
                                },
                                child: Text(
                                  isDescriptionExpanded
                                      ? "Show Less ▲"
                                      : "Show More ▼",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // ✅ RATINGS HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ratings",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AllRatingsScreen(dressId: dress!.id),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "See All Ratings",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // ✅ AVERAGE RATING
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  dress!.averageRating.round(),
                                  (index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                dress!.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ✅ LAST 3 REVIEWS
                          if (dress!.reviews.isNotEmpty)
                            Column(
                              children: dress!.reviews
                                  .map(
                                    (review) => Container(
                                      margin: const EdgeInsets.only(bottom: 15),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                review.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  review.rating,
                                                  (index) => const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            review.date
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          else
                            const Text(
                              "No ratings yet",
                              style: TextStyle(color: Colors.black54),
                            ),

                          const SizedBox(height: 35),

                          // ✅ RENT BUTTON
                          if (dress!.ownerId != UserSession.userId)
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                        dressId: dress!.id,
                                        rentPerDay: dress!.rentPrice,
                                        dressTitle: dress!.title,
                                        sizeStocks: dress!.sizeStocks
                                            .map((s) => {
                                                  'SizeId': s.sizeId,
                                                  'SizeName': s.sizeName,
                                                  'Stock': s.stock,
                                                })
                                            .toList(),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Rent / Advance Book  →",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(35),
                              ),
                              child: const Text(
                                "This is your listing",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
