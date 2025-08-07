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

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      villageId: json['village_ud'] ?? 0,
      provinceId: json['province_id'] ?? 0,
      name: json['name'] ?? "",
      address: json['address'] ?? "",
      salePhone: json['sale_phone'] ?? "",
      zipCode: json['zip_code'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'village_ud': villageId,
      'province_id': provinceId,
      'name': name,
      'address': address,
      'sale_phone': salePhone,
      'zip_code': zipCode,
    };
  }
}
