class LawModel {
  final int lawId;
  final int villageId;
  final int userId;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? phone;
  final String? gender;
  final String? address;
  final String? img;

  LawModel({
    required this.lawId,
    required this.villageId,
    required this.userId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.phone,
    this.gender,
    this.address,
    this.img,
  });

  factory LawModel.fromJson(Map<String, dynamic> json) {
    return LawModel(
      lawId: json['law_id'],
      villageId: json['village_id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthDate: DateTime.parse(json['birth_date']),
      phone: json['phone'],
      gender: json['gender'],
      address: json['address'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'law_id': lawId,
      'village_id': villageId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'phone': phone,
      'gender': gender,
      'address': address,
      'img': img,
    };
  }

  factory LawModel.fromSessionJson(Map<String, dynamic> json) {
    return LawModel(
      lawId: json['law_id'],
      villageId: json['village_id'],
      userId: json['user_id'],
      firstName: json['first_name'],
    );
  }

  Map<String, dynamic> toSessionJson() {
    return {
      'law_id': lawId,
      'village_id': villageId,
      'user_id': userId,
      'first_name': firstName,
    };
  }
}
