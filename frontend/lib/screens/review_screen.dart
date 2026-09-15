import 'package:flutter/material.dart';
import '../services/rental_service.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final int dressId;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.dressId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;
  bool isSubmitting = false;

  Future<void> submitReview() async {
    if (selectedRating == 0) return;

    setState(() => isSubmitting = true);

    final success = await RentalService.submitReview(
      widget.bookingId,
      widget.dressId,
      selectedRating,
    );

    setState(() => isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully")),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to submit review")));
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      iconSize: 40,
      icon: Icon(
        index <= selectedRating ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
      onPressed: () {
        setState(() {
          selectedRating = index;
        });
      },
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
          "Write Review",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Rate This Dress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildStar(1),
                buildStar(2),
                buildStar(3),
                buildStar(4),
                buildStar(5),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: isSubmitting ? null : submitReview,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Review"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
