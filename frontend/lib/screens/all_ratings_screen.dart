import 'package:flutter/material.dart';
import '../services/dress_service.dart';
import '../models/dress_details_model.dart';

class AllRatingsScreen extends StatefulWidget {
  final int dressId;

  const AllRatingsScreen({super.key, required this.dressId});

  @override
  State<AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<AllRatingsScreen> {
  List<ReviewModel> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    final result = await DressService.getAllReviews(widget.dressId);

    setState(() {
      reviews = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text("All Ratings", style: TextStyle(color: Colors.black)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
          ? const Center(child: Text("No ratings yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: List.generate(
                              review.rating,
                              (i) => const Icon(
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
                        review.date.toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
