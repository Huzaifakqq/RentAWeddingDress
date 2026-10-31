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
  bool isLoadingData = true;
  String loadError = "";

  int? selectedCategoryId;
  int? selectedSubCategoryId;

  String selectedGender = "Male";
  double conditionValue = 5;

  final TextEditingController yearsController = TextEditingController(text: "0");
  final TextEditingController monthsController = TextEditingController(text: "0");
  final TextEditingController daysController = TextEditingController(text: "0");

  List<String> selectedOccasions = [];
  List<int> selectedSizeIds = [];
  Map<int, int> sizeStock = {};

  // ✅ Multi-copy upload: each copy gets its own size / age / condition
  int copiesCount = 1;
  final List<CopyEntry> copyEntries = [CopyEntry()];

  final List<String> occasionOptions = ["Mehndi", "Barat", "Walima", "Nikkah"];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    categories = await DressService.getCategories();
    sizes = await DressService.getSizes();
    print("Categories loaded: ${categories.length}");
    print("Sizes loaded: ${sizes.length}");
    if (categories.isEmpty) {
      loadError = "Failed to load categories. Check API connection.";
    }
    setState(() => isLoadingData = false);
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

    // ✅ Validate per-copy details when uploading multiple copies
    if (copiesCount > 1) {
      for (int i = 0; i < copyEntries.length; i++) {
        if (copyEntries[i].sizeId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Select size for Copy ${i + 1}")),
          );
          return;
        }
      }
    }

    await uploadImages();

    final data = <String, dynamic>{
      "UserId": UserSession.userId,
      "Dtitle": titleController.text,
      "CategoryId": selectedCategoryId,
      "SubCategoryId": selectedSubCategoryId,
      "Gender": selectedGender,
      "Condition": conditionValue.toInt(),
      "AgeYears": int.tryParse(yearsController.text) ?? 0,
      "AgeMonths": int.tryParse(monthsController.text) ?? 0,
      "AgeDays": int.tryParse(daysController.text) ?? 0,
      "RentPrice": double.parse(priceController.text),
      "Description": descriptionController.text,
      "Occasions": selectedOccasions,
      "SizeIds": selectedSizeIds,
      "SizeStock": sizeStock.map((k, v) => MapEntry(k.toString(), v)),
      "ImagePaths": uploadedImagePaths,
    };

    // ✅ Multi-copy: one separate listing per copy, each with own age/condition
    if (copiesCount > 1) {
      data["Copies"] = copyEntries.take(copiesCount).map((c) {
        return {
          "SizeId": c.sizeId,
          "AgeYears": int.tryParse(c.years.text) ?? 0,
          "AgeMonths": int.tryParse(c.months.text) ?? 0,
          "AgeDays": int.tryParse(c.days.text) ?? 0,
          "Condition": c.condition.toInt(),
          // ✅ Empty price field → backend uses the listing price below
          "Price": c.price.text.trim().isEmpty
              ? null
              : double.tryParse(c.price.text.trim()),
        };
      }).toList();
    }

    final success = await DressService.createDress(data);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copiesCount > 1
                ? "$copiesCount copies uploaded successfully"
                : "Dress Uploaded Successfully",
          ),
        ),
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
            if (isLoadingData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loadError.isEmpty
                      ? "No categories found"
                      : loadError,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedCategoryId,
                hint: const Text("Select Category"),
                items: categories.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem<int>(
                    value: c['Category_id'] as int,
                    child: Text(c['Cname'].toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                    selectedSubCategoryId = null;
                    subCategories = [];
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
            if (selectedCategoryId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Select category first",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else if (subCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedSubCategoryId,
                hint: const Text("Select Sub Category"),
                items: subCategories.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem<int>(
                    value: s['SubCategory_id'] as int,
                    child: Text(s['SCname'].toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubCategoryId = value;
                  });
                },
              ),
            const SizedBox(height: 25),

            // ✅ NUMBER OF COPIES
            const Text(
              "Number of Copies",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Text(
              "If you have multiple physical copies, set age & condition "
              "of each copy separately — every copy becomes its own listing.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: copiesCount > 1
                      ? () => setCopiesCount(copiesCount - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$copiesCount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: copiesCount < 50
                      ? () => setCopiesCount(copiesCount + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 8),
                const Text(
                  "copy/copies",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (copiesCount > 1)
              // ✅ PER-COPY DETAILS: separate size / age / condition for each copy
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Details for Each Copy",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    copiesCount,
                    (index) => buildCopyCard(index),
                  ),
                ],
              )
            else ...[
              // ✅ CONDITION (single-copy mode)
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

              // ✅ DRESS AGE (single-copy mode)
              const Text(
                "Dress Age",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Years",
                        hintText: "0",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: monthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Months",
                        hintText: "0",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Days",
                        hintText: "0",
                      ),
                    ),
                  ),
                ],
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
                        if (!selected) sizeStock[id] = 1;
                      });
                    },
                  );
                }).toList(),
              ),

              // ✅ STOCK INPUTS FOR EACH SELECTED SIZE
              if (selectedSizeIds.isNotEmpty) ...[
                const SizedBox(height: 15),
                const Text(
                  "Stock per Size",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ...selectedSizeIds.map((sizeId) {
                  final sizeName = sizes
                      .firstWhere((s) => s['Size_id'] == sizeId)['SizeName'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(sizeName),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Qty",
                            ),
                            controller: TextEditingController(
                              text: (sizeStock[sizeId] ?? 1).toString(),
                            ),
                            onChanged: (val) {
                              sizeStock[sizeId] = int.tryParse(val) ?? 1;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],

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

  // ✅ Resize per-copy entries to match the chosen copies count
  void setCopiesCount(int count) {
    if (count < 1) count = 1;
    if (count > 50) count = 50;
    setState(() {
      copiesCount = count;
      while (copyEntries.length < count) {
        copyEntries.add(CopyEntry());
      }
    });
  }

  // ✅ One card per physical copy: its own size, age and condition
  Widget buildCopyCard(int index) {
    final entry = copyEntries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Copy ${index + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Size
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: entry.sizeId,
            hint: const Text("Select Size"),
            items: sizes.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: s['Size_id'] as int,
                child: Text(s['SizeName'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                entry.sizeId = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Age
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.years,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Years"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.months,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Months"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Days"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Condition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Condition",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "${entry.condition.toInt()}/10",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.black,
            value: entry.condition,
            label: entry.condition.toInt().toString(),
            onChanged: (val) {
              setState(() {
                entry.condition = val;
              });
            },
          ),
          const SizedBox(height: 4),

          // ✅ Optional per-copy price (blank = use listing price below)
          TextField(
            controller: entry.price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Price for this copy (Rs/day)",
              hintText: "Blank = listing price",
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Holds one physical copy's details on the upload screen
class CopyEntry {
  final TextEditingController years = TextEditingController(text: "0");
  final TextEditingController months = TextEditingController(text: "0");
  final TextEditingController days = TextEditingController(text: "0");
  final TextEditingController price = TextEditingController();
  double condition = 5;
  int? sizeId;
}
