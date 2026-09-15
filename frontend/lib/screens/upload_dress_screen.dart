import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_a_wedding_dress/screens/dresses_screen.dart';
import '../services/dress_service.dart';
import '../models/user_session.dart';

class UploadDressScreen extends StatefulWidget {
  const UploadDressScreen({super.key});

  @override
  State<UploadDressScreen> createState() => _UploadDressScreenState();
}

class _UploadDressScreenState extends State<UploadDressScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<File> selectedImages = [];
  List<String> uploadedImagePaths = [];

  List categories = [];
  List subCategories = [];
  List sizes = [];

  int? selectedCategoryId;
  int? selectedSubCategoryId;

  String selectedGender = "Male";
  double conditionValue = 5;

  List<String> selectedOccasions = [];
  List<int> selectedSizeIds = [];

  final List<String> occasionOptions = ["Mehndi", "Barat", "Walima", "Nikkah"];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    categories = await DressService.getCategories();
    sizes = await DressService.getSizes();
    setState(() {});
  }

  Future<void> loadSubCategories(int categoryId) async {
    subCategories = await DressService.getSubCategories(categoryId);
    setState(() {});
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((e) => File(e.path)).toList());
      });
    }
  }

  Future<void> uploadImages() async {
    uploadedImagePaths.clear();

    for (var image in selectedImages) {
      final path = await DressService.uploadImage(image);
      if (path != null) {
        uploadedImagePaths.add(path);
      }
    }
  }

  Future<void> submitDress() async {
    if (UserSession.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (titleController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedCategoryId == null ||
        selectedSubCategoryId == null ||
        selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    await uploadImages();

    final success = await DressService.createDress({
      "UserId": UserSession.userId,
      "Dtitle": titleController.text,
      "CategoryId": selectedCategoryId,
      "SubCategoryId": selectedSubCategoryId,
      "Gender": selectedGender,
      "Condition": conditionValue.toInt(),
      "RentPrice": double.parse(priceController.text),
      "Description": descriptionController.text,
      "Occasions": selectedOccasions,
      "SizeIds": selectedSizeIds,
      "ImagePaths": uploadedImagePaths,
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dress Uploaded Successfully")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DressesScreen()),
      );
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Upload Dress",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ IMAGES
            const Text(
              "Dress Images",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: pickImages,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: selectedImages.isEmpty
                    ? const Center(child: Text("Tap to upload photos"))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 5,
                                top: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 25),

            // ✅ TITLE
            const Text("Title", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Enter dress title"),
            ),

            const SizedBox(height: 25),

            // ✅ GENDER (Custom Toggle)
            const Text("Gender", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Row(
              children: [
                buildGenderButton("Male"),
                const SizedBox(width: 10),
                buildGenderButton("Female"),
              ],
            ),

            const SizedBox(height: 25),

            // ✅ OCCASION
            const Text(
              "Occasion",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: occasionOptions
                  .map(
                    (o) => ChoiceChip(
                      label: Text(o),
                      selected: selectedOccasions.contains(o),
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selectedOccasions.contains(o)
                            ? Colors.white
                            : Colors.black,
                      ),
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (val) {
                        setState(() {
                          selectedOccasions.contains(o)
                              ? selectedOccasions.remove(o)
                              : selectedOccasions.add(o);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 25),

            // ✅ CATEGORY
            const Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<int>(
              items: categories.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['Category_id'],
                  child: Text(c['Cname']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;

                  // ✅ Reset immediately
                  selectedSubCategoryId = null;
                  subCategories = []; // clear old list
                });

                loadSubCategories(value!);
              },
            ),

            const SizedBox(height: 25),

            // ✅ SUBCATEGORY
            const Text(
              "Sub Category",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<int>(
              value:
                  subCategories.any(
                    (s) => s['SubCategory_id'] == selectedSubCategoryId,
                  )
                  ? selectedSubCategoryId
                  : null,
              items: subCategories.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem<int>(
                  value: s['SubCategory_id'],
                  child: Text(s['SCname']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 25),

            // ✅ CONDITION
            const Text(
              "Condition",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.black,
              value: conditionValue,
              label: conditionValue.toInt().toString(),
              onChanged: (val) {
                setState(() {
                  conditionValue = val;
                });
              },
            ),

            const SizedBox(height: 25),

            // ✅ SIZES
            const Text(
              "Available Sizes",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: sizes.map((s) {
                final id = s['Size_id'];
                final selected = selectedSizeIds.contains(id);
                return ChoiceChip(
                  label: Text(s['SizeName']),
                  selected: selected,
                  selectedColor: Colors.black,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (val) {
                    setState(() {
                      selected
                          ? selectedSizeIds.remove(id)
                          : selectedSizeIds.add(id);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // ✅ RENT PRICE
            const Text(
              "Rental Cost (per day)",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "e.g., Rs.3000"),
            ),

            const SizedBox(height: 25),

            // ✅ DESCRIPTION
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: "Enter description"),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: submitDress,
                child: const Text(
                  "Submit Listing",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildGenderButton(String gender) {
    final selected = selectedGender == gender;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            gender,
            style: TextStyle(color: selected ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
