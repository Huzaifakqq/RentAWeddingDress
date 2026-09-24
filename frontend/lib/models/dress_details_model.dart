class ReviewModel {
  final String userName;
  final DateTime date;
  final int rating;
  final String? feedback;

  ReviewModel({
    required this.userName,
    required this.date,
    required this.rating,
    this.feedback,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      userName: json['UserName'],
      date: DateTime.parse(json['Date']),
      rating: json['Rating'],
      feedback: json['Feedback'],
    );
  }
}

class SizeStockModel {
  final int sizeId;
  final String sizeName;
  final int stock;

  SizeStockModel({
    required this.sizeId,
    required this.sizeName,
    required this.stock,
  });

  factory SizeStockModel.fromJson(Map<String, dynamic> json) {
    return SizeStockModel(
      sizeId: json['SizeId'],
      sizeName: json['SizeName'],
      stock: json['Stock'],
    );
  }
}

class DressDetailsModel {
  final int id;
  final int ownerId;
  final String title;
  final double rentPrice;
  final String gender;
  final int condition;
  final String ageDisplay;
  final String category;
  final String subCategory;
  final String description;
  final List<String> images;
  final List<String> occasions;
  final List<String> sizes;
  final List<SizeStockModel> sizeStocks;
  final double averageRating;
  final List<ReviewModel> reviews;

  DressDetailsModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.rentPrice,
    required this.gender,
    required this.condition,
    required this.ageDisplay,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.images,
    required this.occasions,
    required this.sizes,
    required this.sizeStocks,
    required this.averageRating,
    required this.reviews,
  });

  factory DressDetailsModel.fromJson(Map<String, dynamic> json) {
    return DressDetailsModel(
      id: json['D_id'],
      ownerId: json['OwnerId'],
      title: json['Title'],
      rentPrice: (json['RentPrice'] as num).toDouble(),
      gender: json['Gender'],
      condition: json['Condition'],
      ageDisplay: json['AgeDisplay'],
      category: json['Category'],
      subCategory: json['SubCategory'],
      description: json['Description'] ?? "",
      images: List<String>.from(json['Images']),
      occasions: List<String>.from(json['Occasions']),
      sizes: List<String>.from(json['Sizes']),
      sizeStocks: (json['SizeStocks'] as List)
          .map((e) => SizeStockModel.fromJson(e))
          .toList(),
      averageRating: (json['AverageRating'] as num).toDouble(),
      reviews: (json['Reviews'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList(),
    );
  }
}
