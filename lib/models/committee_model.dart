class CommitteeModel {
  final int? villageId;
  final int? houseId;
  final int? committeeId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? img;

  CommitteeModel({
    this.villageId,
    this.houseId,
    this.committeeId,
    this.firstName,
    this.lastName,
    this.phone,
    this.img,
  });

  // Factory constructor for creating from JSON
  factory CommitteeModel.fromJson(Map<String, dynamic> json) {
    return CommitteeModel(
      villageId: json['village_id'] as int?,
      houseId: json['house_id'] as int?,
      committeeId: json['committee_id'] as int?,
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      img: json['img'],
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'village_id': villageId,
      'house_id': houseId,
      'committee_id': committeeId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'img': img,
    };
  }
}
