class DressModel {
  final int id;
  final String title;
  final double rentPrice;
  final String gender;
  final String? image;
  final String? occasion;
  final double rating;

  DressModel({
    required this.id,
    required this.title,
    required this.rentPrice,
    required this.gender,
    required this.image,
    required this.occasion,
    required this.rating,
  });

  factory DressModel.fromJson(Map<String, dynamic> json) {
    return DressModel(
      id: json['D_id'],
      title: json['Title'] ?? '',
      rentPrice: (json['RentPrice'] ?? 0).toDouble(),
      gender: json['Gender'] ?? '',
      image: json['Image'],
      occasion: json['Occasion'],
      rating: (json['Rating'] ?? 0).toDouble(),
    );
  }
}
