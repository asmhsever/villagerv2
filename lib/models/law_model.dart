class LawModel {
  final int lawId;
  final int villageId;
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? birthDate;
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
      birthDate: json['birth_date'],
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

  /// แบบย่อไว้ใช้กับ session
  Map<String, dynamic> toSessionJson() {
    return {
      'law_id': lawId,
      'first_name': firstName,
      'last_name': lastName,
      'village_id': villageId,
      'user_id': userId,
    };
  }

  /// ชื่อเต็ม
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return '';
  }

  LawModel copyWith({
    int? lawId,
    int? villageId,
    int? userId,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? phone,
    String? gender,
    String? address,
    String? img,
  }) {
    return LawModel(
      lawId: lawId ?? this.lawId,
      villageId: villageId ?? this.villageId,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      img: img ?? this.img,
    );
  }
}