// 🚗 VehicleModel - Complete Model สำหรับยานพาหนะ
class VehicleModel {
  final int vehicleId;
  final int houseId;
  final String? brand;
  final String? model;
  final String? number;
  final String? img;

  VehicleModel({
    required this.vehicleId,
    required this.houseId,
    this.brand,
    this.model,
    this.number,
    this.img,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicle_id'] ?? 0,
      houseId: json['house_id'] ?? 0,
      brand: json['brand'],
      model: json['model'],
      number: json['number'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'house_id': houseId,
      'brand': brand,
      'model': model,
      'number': number,
      'img': img,
    };
  }

  // 🆕 Helper methods
  String get displayName {
    if ((brand == null || brand!.isEmpty) && (model == null || model!.isEmpty)) {
      return 'ยานพาหนะ';
    }
    if (brand == null || brand!.isEmpty) return model!;
    if (model == null || model!.isEmpty) return brand!;
    return '$brand $model';
  }

  String get displayNumber => number ?? 'ไม่มีทะเบียน';

  String get fullDisplayName {
    final name = displayName;
    final plate = displayNumber;
    if (plate == 'ไม่มีทะเบียน') return name;
    return '$name ($plate)';
  }

  bool get hasImage => img != null && img!.isNotEmpty;

  bool get hasCompleteInfo =>
      (brand != null && brand!.isNotEmpty) &&
          (model != null && model!.isNotEmpty) &&
          (number != null && number!.isNotEmpty);

  // 🆕 สำหรับ debugging
  @override
  String toString() {
    return 'VehicleModel(id: $vehicleId, brand: $brand, model: $model, number: $number)';
  }

  // 🆕 สำหรับ comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleModel && other.vehicleId == vehicleId;
  }

  @override
  int get hashCode => vehicleId.hashCode;
}

// 🏘️ VillageModel - แก้ไขแล้ว
class VillageModel {
  final int villageId;
  final int provinceId;
  final String? name;
  final String? address;
  final String? salePhone;
  final String? zipCode;

  VillageModel({
    required this.villageId,
    required this.provinceId,
    this.name,
    this.address,
    this.salePhone,
    this.zipCode,
  });

  // 🔧 แก้ไข JSON mapping
  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      villageId: json['village_id'] ?? 0,    // ✅ แก้ไขจาก 'village_ud'
      provinceId: json['province_id'] ?? 0,
      name: json['name'] ?? "",
      address: json['address'] ?? "",
      salePhone: json['sale_phone'] ?? "",
      zipCode: json['zip_code'] ?? "",
    );
  }

  // 🔧 แก้ไข JSON mapping  
  Map<String, dynamic> toJson() {
    return {
      'village_id': villageId,    // ✅ แก้ไขจาก 'village_ud'
      'province_id': provinceId,
      'name': name,
      'address': address,
      'sale_phone': salePhone,
      'zip_code': zipCode,
    };
  }

  // 🆕 เพิ่ม helper methods
  String get displayName => name ?? 'ไม่มีชื่อ';

  String get fullAddress {
    if (address == null || address!.isEmpty) return 'ไม่มีที่อยู่';
    if (zipCode == null || zipCode!.isEmpty) return address!;
    return '$address $zipCode';
  }

  bool get hasContactInfo => salePhone != null && salePhone!.isNotEmpty;

  String get displayPhone => salePhone ?? 'ไม่มีเบอร์โทร';

  bool get hasCompleteInfo =>
      (name != null && name!.isNotEmpty) &&
          (address != null && address!.isNotEmpty);

  // 🆕 สำหรับ debugging
  @override
  String toString() {
    return 'VillageModel(id: $villageId, name: $name, address: $address)';
  }

  // 🆕 สำหรับ comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VillageModel && other.villageId == villageId;
  }

  @override
  int get hashCode => villageId.hashCode;
}