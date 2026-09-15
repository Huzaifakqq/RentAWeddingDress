import 'package:flutter/material.dart';
import '../services/dress_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? existingFilters;

  const FilterBottomSheet({super.key, this.existingFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List categories = [];
  List subCategories = [];
  List sizes = [];

  int? selectedCategoryId;
  int? selectedSubCategoryId;
  String? selectedGender;
  String? selectedOccasion;
  DateTimeRange? selectedDate;
  List<int> selectedSizeIds = [];

  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  double conditionValue = 0; // 0 means no filter

  @override
  void initState() {
    super.initState();
    loadInitialData();
    loadExistingFilters();
  }

  void loadExistingFilters() {
    final filters = widget.existingFilters;

    if (filters != null) {
      selectedCategoryId = filters["CategoryId"];
      selectedSubCategoryId = filters["SubCategoryId"];
      selectedGender = filters["Gender"];
      selectedOccasion = filters["Occasion"];
      selectedSizeIds = List<int>.from(filters["SizeIds"] ?? []);

      // ✅ Restore Date
      if (filters["StartDate"] != null && filters["EndDate"] != null) {
        selectedDate = DateTimeRange(
          start: DateTime.parse(filters["StartDate"]),
          end: DateTime.parse(filters["EndDate"]),
        );
      }

      // ✅ ✅ RESTORE PRICE
      if (filters["MinPrice"] != null) {
        minPriceController.text = filters["MinPrice"].toString();
      }

      if (filters["MaxPrice"] != null) {
        maxPriceController.text = filters["MaxPrice"].toString();
      }

      // ✅ ✅ RESTORE CONDITION
      if (filters["Condition"] != null) {
        conditionValue = (filters["Condition"] as num).toDouble();
      }

      if (selectedCategoryId != null) {
        loadSubCategories(selectedCategoryId!);
      }
    }
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

  void resetFilters() {
    setState(() {
      selectedCategoryId = null;
      selectedSubCategoryId = null;
      selectedGender = null;
      selectedOccasion = null;
      selectedDate = null;
      selectedSizeIds = [];
      subCategories = [];

      minPriceController.clear();
      maxPriceController.clear();
      conditionValue = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 700,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filters",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(labelText: "Gender"),
              items: const [
                DropdownMenuItem(value: null, child: Text("All")),
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
              ],
              onChanged: (value) {
                selectedGender = value;
              },
            ),

            DropdownButtonFormField<int>(
              value: selectedCategoryId,
              decoration: const InputDecoration(labelText: "Category"),
              items: categories.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['Category_id'],
                  child: Text(c['Cname']),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategoryId = value;
                loadSubCategories(value!);

                final selectedCategory = categories.firstWhere(
                  (c) => c['Category_id'] == value,
                );

                if (selectedCategory['Cname'] == "Bridal") {
                  selectedGender = "Female";
                } else if (selectedCategory['Cname'] == "Groom") {
                  selectedGender = "Male";
                } else {
                  selectedGender = null;
                }
                setState(() {});
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value:
                  subCategories.any(
                    (s) => s['SubCategory_id'] == selectedSubCategoryId,
                  )
                  ? selectedSubCategoryId
                  : null,
              decoration: const InputDecoration(labelText: "Sub Category"),
              items: subCategories.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem<int>(
                  value: s['SubCategory_id'],
                  child: Text(s['SCname']),
                );
              }).toList(),
              onChanged: (value) {
                selectedSubCategoryId = value;
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedOccasion,
              decoration: const InputDecoration(labelText: "Occasion"),
              items: const [
                DropdownMenuItem(value: "Mehndi", child: Text("Mehndi")),
                DropdownMenuItem(value: "Nikkah", child: Text("Nikkah")),
                DropdownMenuItem(value: "Walima", child: Text("Walima")),
                DropdownMenuItem(value: "Barat", child: Text("Barat")),
              ],
              onChanged: (value) {
                selectedOccasion = value;
              },
            ),

            const SizedBox(height: 15),

            const Text(
              "Price Range",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Min Price"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Max Price"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 15),

            const Text("Sizes", style: TextStyle(fontWeight: FontWeight.bold)),

            Wrap(
              children: sizes.map<Widget>((size) {
                final sizeId = size['Size_id'];
                return CheckboxListTile(
                  title: Text(size['SizeName']),
                  value: selectedSizeIds.contains(sizeId),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedSizeIds.add(sizeId);
                      } else {
                        selectedSizeIds.remove(sizeId);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 20),

            const Text(
              "Condition",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Slider(
              value: conditionValue,
              min: 0,
              max: 10,
              divisions: 10,
              label: conditionValue == 0
                  ? "Any"
                  : conditionValue.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  conditionValue = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDateRange: selectedDate, // ✅ THIS LINE FIXES IT
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(
                selectedDate == null
                    ? "Select Dates"
                    : "${selectedDate!.start.day}/${selectedDate!.start.month}/${selectedDate!.start.year} "
                          "- "
                          "${selectedDate!.end.day}/${selectedDate!.end.month}/${selectedDate!.end.year}",
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: resetFilters,
                    child: const Text("Reset Filters"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "CategoryId": selectedCategoryId,
                        "SubCategoryId": selectedSubCategoryId,
                        "Gender": selectedGender,
                        "Occasion": selectedOccasion,
                        "SizeIds": selectedSizeIds,
                        "StartDate": selectedDate?.start.toIso8601String(),
                        "EndDate": selectedDate?.end.toIso8601String(),
                        "MinPrice": minPriceController.text.isNotEmpty
                            ? double.parse(minPriceController.text)
                            : null,
                        "MaxPrice": maxPriceController.text.isNotEmpty
                            ? double.parse(maxPriceController.text)
                            : null,
                        "Condition": conditionValue > 0
                            ? conditionValue.toInt()
                            : null,
                      });
                    },
                    child: const Text("Apply Filters"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
