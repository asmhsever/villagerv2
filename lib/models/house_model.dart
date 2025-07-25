class HouseModel {
  final int houseId;
  final int villageId;
  final int userId;
  final String? size;
  final String? houseNumber;
  final String? phone;
  final String? owner;
  final String? status;
  final String? houseType;
  final int? floors;
  final String? usableArea;
  final String? usageStatus;
  final String? img;

  HouseModel({
    required this.houseId,
    required this.villageId,
    required this.userId,
    this.size,
    this.houseNumber,
    this.phone,
    this.owner,
    this.status,
    this.houseType,
    this.floors,
    this.usableArea,
    this.usageStatus,
    this.img,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) {
    return HouseModel(
      houseId: json['house_id'],
      villageId: json['village_id'],
      userId: json['user_id'],
      size: json['size'],
      houseNumber: json['house_number'],
      phone: json['phone'],
      owner: json['owner'],
      status: json['status'],
      houseType: json['house_type'],
      floors: json['floors'],
      usableArea: json['usable_area'],
      usageStatus: json['usage_status'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'house_id': houseId,
      'village_id': villageId,
      'user_id': userId,
      'size': size,
      'house_number': houseNumber,
      'phone': phone,
      'owner': owner,
      'status': status,
      'house_type': houseType,
      'floors': floors,
      'usable_area': usableArea,
      'usage_status': usageStatus,
      'img': img,
    };
  }

  /// แบบย่อไว้ใช้กับ session
  Map<String, dynamic> toSessionJson() {
    return {
      'house_id': houseId,
      'owner': owner,
      'village_id': villageId,
      'user_id': userId,
    };
  }
}
