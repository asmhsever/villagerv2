// lib/models/house_model.dart
// HouseModel with ownershipType added and full mapping to DB columns.

class HouseModel {
  final int houseId;
  final int villageId;
  final int userId;

  final String? size;
  final String? houseNumber;
  final String? phone;
  final String? owner;
  final String? status;

  /// NEW: map to DB column `ownership_type`
  final String? ownershipType;

  final String? houseType;
  final int? floors;
  final String? usableArea;
  final String? usageStatus;
  final String? img;

  const HouseModel({
    required this.houseId,
    required this.villageId,
    required this.userId,
    this.size,
    this.houseNumber,
    this.phone,
    this.owner,
    this.status,
    this.ownershipType, // <—
    this.houseType,
    this.floors,
    this.usableArea,
    this.usageStatus,
    this.img,
  });

  /// WHY: keep DB ↔ Dart mapping in one place, match HouseDomain signatures.
  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      houseId: map['house_id'] is String
          ? int.parse(map['house_id'])
          : map['house_id'] as int,
      villageId: map['village_id'] is String
          ? int.parse(map['village_id'])
          : map['village_id'] as int,
      userId: map['user_id'] is String
          ? int.parse(map['user_id'])
          : map['user_id'] as int,
      size: map['size'] as String?,
      houseNumber: map['house_number'] as String?,
      phone: map['phone'] as String?,
      owner: map['owner'] as String?,
      status: map['status'] as String?,
      ownershipType: map['ownership_type'] as String?, // <—
      houseType: map['house_type'] as String?,
      floors: map['floors'] == null
          ? null
          : (map['floors'] is String
          ? int.tryParse(map['floors'])
          : map['floors'] as int),
      usableArea: map['usable_area'] as String?,
      usageStatus: map['usage_status'] as String?,
      img: map['img'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'house_id': houseId,
      'village_id': villageId,
      'user_id': userId,
      'size': size,
      'house_number': houseNumber,
      'phone': phone,
      'owner': owner,
      'status': status,
      'ownership_type': ownershipType, // <—
      'house_type': houseType,
      'floors': floors,
      'usable_area': usableArea,
      'usage_status': usageStatus,
      'img': img,
    };
  }

  HouseModel copyWith({
    int? houseId,
    int? villageId,
    int? userId,
    String? size,
    String? houseNumber,
    String? phone,
    String? owner,
    String? status,
    String? ownershipType, // <—
    String? houseType,
    int? floors,
    String? usableArea,
    String? usageStatus,
    String? img,
  }) {
    return HouseModel(
      houseId: houseId ?? this.houseId,
      villageId: villageId ?? this.villageId,
      userId: userId ?? this.userId,
      size: size ?? this.size,
      houseNumber: houseNumber ?? this.houseNumber,
      phone: phone ?? this.phone,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      ownershipType: ownershipType ?? this.ownershipType, // <—
      houseType: houseType ?? this.houseType,
      floors: floors ?? this.floors,
      usableArea: usableArea ?? this.usableArea,
      usageStatus: usageStatus ?? this.usageStatus,
      img: img ?? this.img,
    );
  }

  // Optional helpers
  factory HouseModel.fromJson(Map<String, dynamic> json) => HouseModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() =>
      'HouseModel(houseId: $houseId, villageId: $villageId, userId: $userId, '
          'houseNumber: $houseNumber, owner: $owner, ownershipType: $ownershipType, '
          'status: $status, houseType: $houseType, floors: $floors)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is HouseModel &&
              runtimeType == other.runtimeType &&
              houseId == other.houseId;

  @override
  int get hashCode => houseId.hashCode;
}
