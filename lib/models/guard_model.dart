class GuardModel {
  final int guardId;
  final int villageId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? nickname;
  final String? img;

  GuardModel({
    required this.guardId,
    required this.villageId,
    this.firstName,
    this.lastName,
    this.phone,
    this.nickname,
    this.img,
  });

  factory GuardModel.fromJson(Map<String, dynamic> json) {
    return GuardModel(
      guardId: json['guard_id'],
      villageId: json['village_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      nickname: json['nickname'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guard_id': guardId,
      'village_id': villageId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'nickname': nickname,
      'img': img,
    };
  }
}
